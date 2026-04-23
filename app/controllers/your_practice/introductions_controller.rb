module YourPractice
  class IntroductionsController < BaseController
    ALLOWED_TAGS = %w[div br strong em ul ol li].freeze

    def show
    end

    def update
      if therapist.update(introduction_params)
        redirect_to introduction_path, notice: "Introduction updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def introduction_params
      attrs = params.require(:therapist).permit(:practice_description)
      attrs[:practice_description] = sanitize_introduction(attrs[:practice_description])
      attrs
    end

    def sanitize_introduction(html)
      return html if html.blank?
      helpers.sanitize(html, tags: ALLOWED_TAGS, attributes: [])
    end
  end
end
