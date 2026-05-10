module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActionController::ParameterMissing do |error|
        render json: { error: error.message }, status: :bad_request
      end
    end
  end
end
