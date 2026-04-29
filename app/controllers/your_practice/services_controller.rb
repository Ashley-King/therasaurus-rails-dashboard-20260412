module YourPractice
  class ServicesController < BaseController
    def show
      load_form_data
    end

    def update
      ids = Array(params.dig(:therapist, :service_ids)).reject(&:blank?)
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
    end
  end
end
