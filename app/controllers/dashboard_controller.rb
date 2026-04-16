class DashboardController < ApplicationController
  include Authentication
  before_action :require_auth
  before_action :require_profile

  layout "dashboard"

  def show
    if current_therapist.present?
      @therapist = Therapist
        .includes(:profession, :locations, :specialties, :services, :age_groups, :session_formats)
        .find(current_therapist.id)
    end
  end

  # POST /dashboard/test — fake slow endpoint for busy state testing
  def test_submit
    sleep 3
    redirect_to dashboard_path, notice: "Test submit completed successfully!"
  end
end
