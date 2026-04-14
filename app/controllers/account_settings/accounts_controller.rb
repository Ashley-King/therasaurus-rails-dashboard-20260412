module AccountSettings
  class AccountsController < BaseController
    def show
    end

    def update
      url = params[:practice_image_url]
      public_url = fetch_credential!(:R2_PUBLIC_URL)

      unless url.start_with?(public_url)
        return render json: { error: "Invalid image URL" }, status: :unprocessable_entity
      end

      therapist.update!(practice_image_url: url)
      render json: { practice_image_url: url }
    rescue KeyError => e
      Rails.logger.error("R2 upload configuration error: #{e.message}")
      render json: { error: "Profile photo uploads are not configured yet." }, status: :service_unavailable
    end

    private

    def fetch_credential!(key)
      value = Rails.application.credentials.fetch(key)
      raise KeyError, "#{key} is blank" if value.blank?

      value
    end
  end
end
