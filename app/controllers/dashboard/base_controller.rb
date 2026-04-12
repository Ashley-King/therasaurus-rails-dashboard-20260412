module Dashboard
  class BaseController < ApplicationController
    include Authentication
    before_action :require_auth

    layout "dashboard"

    private

    def therapist
      @therapist ||= current_therapist
    end
    helper_method :therapist
  end
end
