module YourPractice
  class TargetedZipsController < BaseController
    def index
      @targeted_zips = therapist.therapist_targeted_zips.order(:created_at)
      @targeted_zip = therapist.therapist_targeted_zips.new
    end

    def create
      @targeted_zip = therapist.therapist_targeted_zips.new(targeted_zip_params)

      if @targeted_zip.save
        redirect_to targeted_zips_path, notice: "Targeted ZIP added."
      else
        @targeted_zips = therapist.therapist_targeted_zips.order(:created_at)
        flash.now[:alert] = @targeted_zip.errors.full_messages.to_sentence.presence ||
                            "Please fix the errors below."
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      targeted_zip = therapist.therapist_targeted_zips.find(params[:id])
      targeted_zip.destroy
      redirect_to targeted_zips_path, notice: "Targeted ZIP removed."
    end

    private

    def targeted_zip_params
      params.require(:targeted_zip).permit(
        :zip, :city, :state, :latitude, :longitude, :city_match_successful
      )
    end
  end
end
