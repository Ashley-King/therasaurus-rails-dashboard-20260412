module YourPractice
  class TargetedPostalCodesController < BaseController
    def index
      @targeted_postal_codes = therapist.therapist_targeted_postal_codes.order(:created_at)
      @targeted_postal_code = therapist.therapist_targeted_postal_codes.new
    end

    def create
      @targeted_postal_code = therapist.therapist_targeted_postal_codes.new(targeted_postal_code_params)

      if @targeted_postal_code.save
        redirect_to targeted_postal_codes_path, notice: t("controllers.targeted_postal_codes.added")
      else
        @targeted_postal_codes = therapist.therapist_targeted_postal_codes.order(:created_at)
        flash.now[:alert] = @targeted_postal_code.errors.full_messages.to_sentence.presence ||
                            t("controllers.targeted_postal_codes.fix_errors")
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      targeted_postal_code = therapist.therapist_targeted_postal_codes.find(params[:id])
      targeted_postal_code.destroy
      redirect_to targeted_postal_codes_path, notice: t("controllers.targeted_postal_codes.removed")
    end

    private

    def targeted_postal_code_params
      params.require(:targeted_postal_code).permit(
        :postal_code, :city, :state, :latitude, :longitude, :city_match_successful
      )
    end
  end
end
