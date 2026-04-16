Avo.configure do |config|
  config.root_path = "/avo"
  config.app_name = "Therasaurus Admin"
  config.current_user_method = :current_user
  config.click_row_to_view_record = true

  config.authenticate_with do
    unless current_user
      redirect_to main_app.signin_path, alert: "Please sign in to continue."
      return
    end

    unless current_user.is_admin?
      redirect_to main_app.dashboard_path, alert: "Admin access required."
    end
  end

  config.authorization_client = nil
  config.explicit_authorization = true
end

Rails.application.config.to_prepare do
  Avo::ApplicationController.include Authentication
end
