module YourPractice
  class PracticeInformationController < BaseController
    def show
    end

    def update
      if therapist.update(practice_information_params)
        redirect_to practice_information_path, notice: "Practice information updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def practice_information_params
      params.require(:therapist).permit(
        :practice_name,
        :use_practice_name,
        :practice_website_url,
        :phone_number,
        :phone_ext,
        :show_phone_number
      )
    end
  end
end
