module YourPractice
  class SocialMediaController < BaseController
    PLATFORMS = %w[facebook instagram linkedin pinterest substack threads tiktok youtube x].freeze

    def show
    end

    def update
      if therapist.update(social_media: social_media_params)
        redirect_to social_media_path, notice: "Social media updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def social_media_params
      submitted = params.require(:therapist).permit(social_media: PLATFORMS).fetch(:social_media, {})
      PLATFORMS.each_with_object({}) do |platform, hash|
        value = submitted[platform].to_s.strip
        hash[platform] = value if value.present?
      end
    end
  end
end
