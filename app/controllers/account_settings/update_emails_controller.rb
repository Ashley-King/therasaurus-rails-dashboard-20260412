module AccountSettings
  class UpdateEmailsController < BaseController
    # Rate limits mirror the auth controller — Supabase itself enforces a
    # separate rate limit, but these keep noisy clients from hammering the
    # endpoint before the request leaves our app.
    rate_limit to: 5, within: 15.minutes,
               only: :update,
               name: "email_change_request",
               by: -> { current_user&.id || request.remote_ip },
               with: -> { rate_limited!(update_email_path, "Too many email change requests. Please try again in a few minutes.") }

    rate_limit to: 10, within: 15.minutes,
               only: :confirm,
               name: "email_change_verify",
               by: -> { current_user&.id || request.remote_ip },
               with: -> { rate_limited!(update_email_path, "Too many verification attempts. Please try again in a few minutes.") }

    # The pending email flow survives exactly one redirect hop via flash.
    # Anything else (reload, direct visit, sidebar click) lands here without
    # the marker and falls through to the email form — which is what the
    # user asked for: a refresh cancels the in-progress change.
    def show
      if flash[:email_change_pending] && session[:pending_new_email].present?
        @pending_new_email = session[:pending_new_email]
      else
        session.delete(:pending_new_email)
        @pending_new_email = nil
      end
    end

    # PATCH — start the change. Sends an OTP to the new address.
    def update
      new_email = params[:email]&.strip&.downcase

      if new_email.blank?
        flash.now[:alert] = "Please enter an email address."
        return render :show, status: :unprocessable_entity
      end

      if new_email == current_user.email
        flash.now[:alert] = "That's already your email address."
        return render :show, status: :unprocessable_entity
      end

      auth_log(:info, "auth.email_change.request_started", user_id: current_user.id)

      begin
        SupabaseAuth.new.request_email_change(
          access_token: session[:access_token],
          new_email: new_email
        )
        session[:pending_new_email] = new_email
        flash[:email_change_pending] = true
        auth_log(:info, "auth.email_change.request_result", user_id: current_user.id, result: "ok")
        redirect_to update_email_path,
          notice: "We sent a verification code to #{new_email}."
      rescue SupabaseAuth::AuthError => e
        auth_log(:warn, "auth.email_change.request_result", user_id: current_user.id, result: "error", error_class: e.class.name)
        flash.now[:alert] = e.message
        render :show, status: :unprocessable_entity
      end
    end

    # POST /confirm — user submits the OTP they received.
    def confirm
      new_email = session[:pending_new_email]
      token = params[:token]&.strip

      if new_email.blank?
        return redirect_to update_email_path,
          alert: "Please request an email change first."
      end

      if token.blank?
        flash[:email_change_pending] = true
        return redirect_to update_email_path, alert: "Please enter the verification code."
      end

      auth_log(:info, "auth.email_change.verify_attempted", user_id: current_user.id)

      begin
        result = SupabaseAuth.new.verify_email_change(email: new_email, token: token)
        store_auth_session(result) if result["access_token"].present?
        current_user.update!(email: new_email)
        session.delete(:pending_new_email)
        auth_log(:info, "auth.email_change.verify_result", user_id: current_user.id, result: "ok")
        redirect_to update_email_path, notice: "Your email has been updated."
      rescue SupabaseAuth::AuthError => e
        auth_log(:warn, "auth.email_change.verify_result", user_id: current_user.id, result: "error", error_class: e.class.name)
        flash[:email_change_pending] = true
        redirect_to update_email_path, alert: e.message
      end
    end

    # DELETE /cancel — discard a pending change so the user can start over.
    def cancel
      session.delete(:pending_new_email)
      redirect_to update_email_path
    end

    private

    def rate_limited!(path, message)
      auth_log(:warn, "auth.rate_limit.email_change", user_id: current_user&.id)
      redirect_to path, alert: message
    end
  end
end
