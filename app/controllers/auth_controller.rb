class AuthController < ApplicationController
  include Authentication

  layout "auth"

  before_action :redirect_if_signed_in, only: [:new, :create, :verify, :confirm]

  # GET /signin
  def new
  end

  # POST /signin
  def create
    email = params[:email]&.strip&.downcase

    if email.blank?
      flash.now[:alert] = "Please enter your email address."
      return render :new, status: :unprocessable_entity
    end

    begin
      SupabaseAuth.new.send_otp(email)
      session[:pending_email] = email
      redirect_to verify_path
    rescue SupabaseAuth::AuthError => e
      flash.now[:alert] = e.message
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

    begin
      result = SupabaseAuth.new.verify_otp(email: email, token: token)
      store_auth_session(result)
      session.delete(:pending_email)

      find_or_create_user!(id: result.dig("user", "id"), email: email)

      redirect_to dashboard_path, notice: "Welcome back!"
    rescue SupabaseAuth::AuthError => e
      flash.now[:alert] = e.message
      @email = email
      render :verify, status: :unprocessable_entity
    end
  end

  # DELETE /signout
  def destroy
    reset_session
    redirect_to signin_path, notice: "You have been signed out."
  end

  private

  def redirect_if_signed_in
    redirect_to dashboard_path if signed_in?
  end

  def find_or_create_user!(id:, email:)
    user = User.find_by(id: id)
    return user if user

    is_admin = AdminEmail.exists?(admin_email: email)
    User.create!(
      id: id,
      email: email,
      is_admin: is_admin,
      membership_status: is_admin ? "pro" : "member"
    )
  end
end
