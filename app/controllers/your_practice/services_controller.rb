module YourPractice
  class ServicesController < BaseController
    MAX_SERVICES = 20

    def show
      load_form_data
    end

    def update
      ids = Array(params.dig(:therapist, :service_ids)).reject(&:blank?).uniq.first(MAX_SERVICES)
      therapist.service_ids = ids
      redirect_to services_path, notice: "Services updated."
    end

    private

    def load_form_data
      @service_categories = ServiceCategory.order(:name).pluck(:id, :name)
      @services = Service
        .includes(:service_categories)
        .order(Arel.sql("lower(name)"))
        .map do |s|
          {
            id: s.id,
            name: s.name,
            category_ids: s.service_categories.map(&:id)
          }
        end
      @selected_service_ids = therapist.service_ids.map(&:to_s)
      @max_services = MAX_SERVICES
    end
  end
end
