module Dashboard
  class PracticeDetailsController < BaseController
    def show
      @locations = therapist.locations.order(:location_type)
    end

    def update
      if therapist.update(practice_details_params)
        redirect_to dashboard_practice_details_path, notice: "Practice details updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def practice_details_params
      params.require(:therapist).permit(
        :practice_name, :use_practice_name, :practice_website_url,
        :practice_video_url, :practice_description,
        :phone_number, :phone_ext, :show_phone_number
      )
    end
  end
end
