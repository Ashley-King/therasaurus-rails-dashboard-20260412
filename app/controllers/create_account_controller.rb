class CreateAccountController < ApplicationController
  include Authentication

  layout "auth"

  before_action :require_auth
  before_action :redirect_if_profile_complete

  # GET /create-account
  def new
  end

  # POST /create-account
  def create
    # Phase 2: form submission logic
    head :not_found
  end

  private

  def redirect_if_profile_complete
    return if current_user.is_admin?

    redirect_to dashboard_path if profile_complete?
  end
end
