module YourPractice
  class AccessibilityController < BaseController
    def show
      @accessibility_options = AccessibilityOption.order(:name)
    end

    def update
      option_ids = params.dig(:therapist, :accessibility_option_ids)&.reject(&:blank?) || []
      therapist.accessibility_option_ids = option_ids
      redirect_to accessibility_path, notice: "Accessibility updated."
    end
  end
end
