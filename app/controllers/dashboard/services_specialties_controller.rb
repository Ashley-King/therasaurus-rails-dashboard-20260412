module Dashboard
  class ServicesSpecialtiesController < BaseController
    def show
      @specialties = Specialty.order(:name)
      @services = Service.order(:name)
      @age_groups = AgeGroup.order(:name)
    end

    def update
      if therapist.update(services_specialties_params)
        redirect_to dashboard_services_specialties_path, notice: "Services and specialties updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def services_specialties_params
      params.require(:therapist).permit(
        specialty_ids: [],
        service_ids: [],
        age_group_ids: []
      )
    end
  end
end
