module YourPractice
  class AvailabilityController < BaseController
    def show
      @session_formats = SessionFormat.order(:name)
      @telehealth_platforms = TelehealthPlatform.order(:name)
    end

    def update
      if therapist.update(availability_params)
        redirect_to availability_path, notice: "Availability updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        @session_formats = SessionFormat.order(:name)
        @telehealth_platforms = TelehealthPlatform.order(:name)
        render :show, status: :unprocessable_entity
      end
    end

    private

    def availability_params
      params.require(:therapist).permit(
        :in_person, :virtual,
        :early_morning, :evening, :weekend,
        :availability_notes, :telehealth_platform_other,
        session_format_ids: [], telehealth_platform_ids: []
      )
    end
  end
end
