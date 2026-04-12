class DashboardController < ApplicationController
  include Authentication
  before_action :require_auth

  layout "dashboard"

  def show
  end

  # POST /dashboard/test — fake slow endpoint for busy state testing
  def test_submit
    sleep 3
    redirect_to dashboard_path, notice: "Test submit completed successfully!"
  end
end
