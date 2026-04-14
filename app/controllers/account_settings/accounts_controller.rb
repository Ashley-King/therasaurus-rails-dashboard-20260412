module AccountSettings
  class AccountsController < BaseController
    def show
    end

    def update
      url = params[:practice_image_url]
      public_url = Rails.application.credentials.R2_PUBLIC_URL

      unless url.start_with?(public_url)
        return render json: { error: "Invalid image URL" }, status: :unprocessable_entity
      end

      therapist.update!(practice_image_url: url)
      render json: { practice_image_url: url }
    end
  end
end
