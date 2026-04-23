module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :current_therapist, :signed_in?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = load_current_user
  end

  def current_therapist
    @current_therapist ||= current_user&.therapist
  end

  def signed_in?
    current_user.present?
  end

  private

  def require_auth
    unless signed_in?
      auth_log(:info, "authz.denied", reason: "not_signed_in", path: request.path)
      redirect_to signin_path, alert: "Please sign in to continue."
    end
  end

  def require_profile
    return unless signed_in?

    unless profile_complete?
      auth_log(:info, "authz.denied", user_id: current_user&.id, reason: "profile_incomplete", path: request.path)
      redirect_to create_account_path
    end
  end

  # Emit a structured auth/authz log line. Always PII-free: no email, no OTP,
  # no JWTs. IP and user agent are always included so we can investigate
  # suspicious activity without needing the full request log.
  def auth_log(level, event, **fields)
    payload = {
      event: event,
      ip: request&.remote_ip,
      ua: request&.user_agent&.to_s&.truncate(200)
    }.merge(fields).compact

    message = payload.map { |k, v| "#{k}=#{v}" }.join(" ")
    Rails.logger.public_send(level, message)
  end

  def profile_complete?
    current_therapist.present?
  end

  def load_current_user
    access_token = session[:access_token]
    return nil unless access_token

    payload = decode_jwt(access_token)
    return handle_expired_token if payload.nil?

    user_id = payload["sub"]
    User.find_by(id: user_id)
  end

  def decode_jwt(token)
    payload = JWT.decode(token, nil, false).first # Skip signature verification — Supabase issued.
    return nil if jwt_expired?(payload)
    payload
  rescue JWT::DecodeError
    auth_log(:warn, "auth.session.invalid", reason: "jwt_invalid")
    nil
  end

  # A 30s skew guards against calls that decode the token, then hand it to
  # Supabase a moment later and find it expired in flight.
  def jwt_expired?(payload)
    exp = payload&.dig("exp")
    return true unless exp

    Time.at(exp) <= Time.current + 30.seconds
  end

  def handle_expired_token
    refresh_token = session[:refresh_token]
    unless refresh_token
      auth_log(:info, "auth.session.invalid", reason: "jwt_expired_no_refresh")
      return clear_session_and_return_nil
    end

    begin
      result = SupabaseAuth.new.refresh_session(refresh_token)
      store_auth_session(result)
      user_id = decode_jwt(result["access_token"])&.dig("sub")
      auth_log(:info, "auth.session.refreshed", user_id: user_id)
      User.find_by(id: user_id)
    rescue SupabaseAuth::AuthError => e
      auth_log(:warn, "auth.session.invalid", reason: "refresh_failed", error_class: e.class.name)
      clear_session_and_return_nil
    end
  end

  def store_auth_session(auth_result)
    session[:access_token] = auth_result["access_token"]
    session[:refresh_token] = auth_result["refresh_token"]
    session[:user_id] = auth_result.dig("user", "id")
  end

  def clear_session_and_return_nil
    session.delete(:access_token)
    session.delete(:refresh_token)
    session.delete(:user_id)
    nil
  end
end
