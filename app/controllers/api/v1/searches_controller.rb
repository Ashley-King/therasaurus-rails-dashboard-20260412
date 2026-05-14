module Api
  module V1
    class SearchesController < ApplicationController
      skip_forgery_protection

      def create
        result = PublicTherapistSearch.call(
          zip: params[:zip].presence || params[:postal_code],
          therapy: params[:therapy],
          page: params[:page],
          profession_type: params[:profession_type],
          profession_name: params[:profession],
          verified_only: params[:verified_only],
          order_token: params[:order_token].presence || params[:order_seed]
        )

        response.headers["Cache-Control"] = "no-store"
        render json: result, status: result[:ok] ? :ok : :bad_request
      end
    end
  end
end
