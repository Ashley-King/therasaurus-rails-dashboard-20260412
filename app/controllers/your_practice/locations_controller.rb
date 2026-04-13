module YourPractice
  class LocationsController < BaseController
    def show
      @locations = therapist&.locations&.order(:location_type) || []
    end
  end
end
