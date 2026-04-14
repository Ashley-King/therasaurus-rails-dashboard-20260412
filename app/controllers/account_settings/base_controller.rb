module AccountSettings
  class BaseController < ApplicationController
    include Authentication
    before_action :require_auth
    before_action :require_profile

    layout "dashboard"

    private

    def therapist
      @therapist ||= current_therapist
    end
    helper_method :therapist
  end
end
