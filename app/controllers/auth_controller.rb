class AuthController < ApplicationController
  include Authentication

  layout "auth"

  # Rate limiting — first line of defense for auth abuse. Rack::Attack
  # (config/initializers/rack_attack.rb) runs looser limits at the Rack layer
  # as a fallback. See _docs/_processes/rate-limiting.md.
  rate_limit to: 5, within: 15.minutes,
             only: :create,
             name: "signin_ip",
             with: -> { rate_limited_signin!("signin_ip") }

  rate_limit to: 5, within: 1.hour,
             only: :create,
             name: "signin_email",
             by: -> { params[:email].to_s.strip.downcase.presence || request.remote_ip },
             with: -> { rate_limited_signin!("signin_email") }

  rate_limit to: 10, within: 15.minutes,
             only: :confirm,
             name: "verify_ip",
             with: -> { rate_limited_verify!("verify_ip") }

  rate_limit to: 5, within: 15.minutes,
             only: :google,
             name: "google_signin_ip",
             with: -> { rate_limited_google_signin!("google_signin_ip") }

  before_action :redirect_if_signed_in, only: [ :new, :create, :verify, :confirm, :google ]

  # GET /signin
  def new
    prepare_signin_form
  end

  # POST /signin
  def create
    email = params[:email]&.strip&.downcase
    captcha_token = params[:"cf-turnstile-response"].to_s.strip

    if email.blank?
      flash.now[:alert] = "Please enter your email address."
      prepare_signin_form(email: email)
      return render :new, status: :unprocessable_entity
    end

    if captcha_token.blank?
      flash.now[:alert] = "Please complete the security check."
      prepare_signin_form(email: email)
      return render :new, status: :unprocessable_entity
    end

    auth_log(:info, "auth.otp.send_requested")

    begin
      SupabaseAuth.new.send_otp(email, captcha_token: captcha_token)
      session[:pending_email] = email
      auth_log(:info, "auth.otp.send_result", result: "ok")
      redirect_to verify_path
    rescue SupabaseAuth::AuthError => e
      auth_log(:warn, "auth.otp.send_result", result: "error", error_class: e.class.name)
      flash.now[:alert] = signin_error_message(e.message)
      prepare_signin_form(email: email)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /verify — fallback for direct URL access
  def verify
    @email = session[:pending_email]
    redirect_to signin_path, alert: "Please enter your email first." unless @email
  end

  # POST /verify
  def confirm
    email = session[:pending_email]
    token = params[:token]&.strip

    if email.blank?
      return redirect_to signin_path, alert: "Please enter your email first."
    end

    if token.blank?
      flash.now[:alert] = "Please enter the verification code."
      @email = email
      return render :verify, status: :unprocessable_entity
    end

    auth_log(:info, "auth.otp.verify_attempted")

    begin
      result = SupabaseAuth.new.verify_otp(email: email, token: token)
      session.delete(:pending_email)

      user = finish_sign_in!(auth_result: result, email: email, provider: "email")
      auth_log(:info, "auth.otp.verify_result", result: "ok", user_id: user.id)

      redirect_after_sign_in(user)
    rescue SupabaseAuth::AuthError => e
      auth_log(:warn, "auth.otp.verify_result", result: "error", error_class: e.class.name)
      flash.now[:alert] = e.message
      @email = email
      render :verify, status: :unprocessable_entity
    end
  end

  # POST /signin/google
  def google
    code_verifier = SupabaseAuth.generate_code_verifier
    code_challenge = SupabaseAuth.code_challenge_for(code_verifier)

    session[:google_oauth_code_verifier] = code_verifier
    session.delete(:pending_email)

    auth_log(:info, "auth.oauth.google.start_requested")

    redirect_to(
      SupabaseAuth.new.oauth_authorize_url(
        provider: "google",
        redirect_to: signin_google_callback_url,
        code_challenge: code_challenge
      ),
      allow_other_host: true,
      status: :see_other
    )
  end

  # GET /signin/google/callback
  def google_callback
    if params[:error].present?
      clear_google_oauth_session
      auth_log(:warn, "auth.oauth.google.callback_result", result: "error", error: params[:error])
      return redirect_to signin_path, alert: "Google sign-in was canceled. Please try again."
    end

    auth_code = params[:code].to_s
    code_verifier = session[:google_oauth_code_verifier].to_s

    if auth_code.blank? || code_verifier.blank?
      clear_google_oauth_session
      auth_log(:warn, "auth.oauth.google.callback_result", result: "invalid_callback")
      return redirect_to signin_path, alert: "Google sign-in could not be completed. Please try again."
    end

    auth_log(:info, "auth.oauth.google.callback_started")

    begin
      result = SupabaseAuth.new.exchange_code_for_session(
        auth_code: auth_code,
        code_verifier: code_verifier
      )
      clear_google_oauth_session

      email = result.dig("user", "email").to_s.strip.downcase
      if email.blank?
        auth_log(:warn, "auth.oauth.google.callback_result", result: "missing_email")
        return redirect_to signin_path, alert: "Google did not return an email address. Please use email sign-in."
      end

      user = finish_sign_in!(auth_result: result, email: email, provider: "google")
      auth_log(:info, "auth.oauth.google.callback_result", result: "ok", user_id: user.id)

      redirect_after_sign_in(user)
    rescue SupabaseAuth::AuthError => e
      clear_google_oauth_session
      auth_log(:warn, "auth.oauth.google.callback_result", result: "error", error_class: e.class.name)
      redirect_to signin_path, alert: e.message
    end
  end

  # DELETE /signout
  def destroy
    user_id = current_user&.id
    auth_log(:info, "auth.sign_out", user_id: user_id)
    reset_session
    redirect_to signin_path, notice: "You have been signed out."
  end

  private

  # Called when one of the signin rate limits trips. Logs the event with a
  # hashed email (never the raw address) so repeated targeting of the same
  # email is correlatable in Better Stack without leaking PII.
  def rate_limited_signin!(limit_name)
    auth_log(
      :warn,
      "auth.rate_limit.#{limit_name}",
      email_hash: email_fingerprint(params[:email])
    )
    redirect_to signin_path, alert: signin_rate_limit_message(limit_name)
  end

  def rate_limited_verify!(limit_name)
    auth_log(:warn, "auth.rate_limit.#{limit_name}")
    redirect_to verify_path, alert: "Too many verification attempts. Please try again in a few minutes."
  end

  def rate_limited_google_signin!(limit_name)
    auth_log(:warn, "auth.rate_limit.#{limit_name}")
    redirect_to signin_path, alert: "Too many Google sign-in attempts. Please try again in a few minutes."
  end

  def signin_rate_limit_message(limit_name)
    if limit_name == "signin_email"
      "Too many sign-in attempts for this email. Please try again in an hour."
    else
      "Too many sign-in attempts. Please try again in a few minutes."
    end
  end

  def signin_error_message(message)
    return "Please wait a minute before requesting another code." if message.match?(/only .* after \d+ seconds/i)

    message
  end

  def prepare_signin_form(email: nil)
    @email = email
    @turnstile_site_key = Rails.application.credentials.fetch(:TURNSTILE_SITE_KEY)
  end

  # SHA256 fingerprint of the submitted email, truncated. Same input always
  # yields the same fingerprint, so repeated abuse against one email is
  # correlatable — but the raw email never hits the logs.
  def email_fingerprint(email)
    normalized = email.to_s.strip.downcase
    return nil if normalized.blank?

    Digest::SHA256.hexdigest(normalized)[0, 12]
  end

  def redirect_if_signed_in
    return unless signed_in?
    return if current_user.is_admin?

    redirect_to account_settings_path if profile_complete?
  end

  def redirect_after_sign_in(user)
    if profile_complete?
      redirect_to account_settings_path
    else
      auth_log(:info, "auth.profile_gate.redirect", user_id: user.id, to: "create_account")
      redirect_to create_account_path
    end
  end

  def finish_sign_in!(auth_result:, email:, provider:)
    store_auth_session(auth_result)

    user = find_or_create_user!(id: auth_result.dig("user", "id"), email: email)
    @current_user = user
    @current_therapist = nil

    auth_log(:info, "auth.session.created", user_id: user.id, provider: provider)
    user
  end

  def clear_google_oauth_session
    session.delete(:google_oauth_code_verifier)
  end

  def find_or_create_user!(id:, email:)
    user = User.find_by(id: id)
    return user if user

    is_admin = AdminEmail.exists?(admin_email: email)
    user = User.create!(
      id: id,
      email: email,
      is_admin: is_admin,
      membership_status: is_admin ? "pro_member" : "member"
    )
    auth_log(:info, "auth.user.created", user_id: user.id, is_admin: is_admin, membership_status: user.membership_status)
    user
  end
end
