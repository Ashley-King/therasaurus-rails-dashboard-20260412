module AboutYou
  class ProfessionalIdentitiesController < BaseController
    def show
      @professions = Profession.order(:name)
      @genders = Gender.order(:name)
      @race_ethnicities = RaceEthnicity.order(:name)
    end

    def update
      if therapist.update(professional_identity_params)
        update_genders
        update_race_ethnicities
        redirect_to professional_identity_path, notice: "Professional identity updated."
      else
        @professions = Profession.order(:name)
        @genders = Gender.order(:name)
        @race_ethnicities = RaceEthnicity.order(:name)
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def professional_identity_params
      params.require(:therapist).permit(:first_name, :last_name, :credentials, :pronouns, :profession_id)
    end

    def update_genders
      gender_ids = params.dig(:therapist, :gender_ids)&.reject(&:blank?) || []
      therapist.gender_ids = gender_ids
    end

    def update_race_ethnicities
      race_ethnicity_ids = params.dig(:therapist, :race_ethnicity_ids)&.reject(&:blank?) || []
      therapist.race_ethnicity_ids = race_ethnicity_ids
    end
  end
end
