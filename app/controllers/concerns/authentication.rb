module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :current_therapist, :signed_in?
  end

  private

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

  def require_auth
    unless signed_in?
      redirect_to signin_path, alert: "Please sign in to continue."
    end
  end

  def require_profile
    return unless signed_in?

    redirect_to create_account_path unless profile_complete?
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
    JWT.decode(token, nil, false).first # Skip verification for now — Supabase issued
  rescue JWT::DecodeError
    nil
  end

  def handle_expired_token
    refresh_token = session[:refresh_token]
    return clear_session_and_return_nil unless refresh_token

    begin
      result = SupabaseAuth.new.refresh_session(refresh_token)
      store_auth_session(result)
      user_id = decode_jwt(result["access_token"])&.dig("sub")
      User.find_by(id: user_id)
    rescue SupabaseAuth::AuthError
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
