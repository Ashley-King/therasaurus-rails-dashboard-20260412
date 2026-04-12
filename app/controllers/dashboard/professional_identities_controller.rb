module Dashboard
  class ProfessionalIdentitiesController < BaseController
    def show
    end

    def update
      if therapist.update(professional_identity_params)
        redirect_to dashboard_professional_identity_path, notice: "Professional identity updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def professional_identity_params
      params.require(:therapist).permit(
        :first_name, :last_name, :pronouns, :credentials,
        :profession_id, :year_began_practice
      )
    end
  end
end
