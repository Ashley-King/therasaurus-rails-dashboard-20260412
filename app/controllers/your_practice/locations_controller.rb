module YourPractice
  class LocationsController < BaseController
    LOCATION_FIELDS = %i[
      street_address street_address2 zip city state
      latitude longitude city_match_successful show_street_address
    ].freeze

    def show
      load_locations
    end

    def update
      load_locations

      primary_ok = update_primary
      additional_ok = update_or_destroy_additional

      if primary_ok && additional_ok
        redirect_to location_path, notice: "Locations updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def load_locations
      @primary = therapist.locations.find_or_initialize_by(location_type: "primary")
      @additional = therapist.locations.find_by(location_type: "additional")
    end

    def update_primary
      raw = params.dig(:locations, :primary)
      return true if raw.blank?

      @primary.assign_attributes(raw.permit(*LOCATION_FIELDS))
      @primary.save
    end

    def update_or_destroy_additional
      raw = params.dig(:locations, :additional)
      return true if raw.blank?

      if ActiveModel::Type::Boolean.new.cast(raw[:remove]) || additional_blank?(raw)
        @additional&.destroy
        @additional = nil
        return true
      end

      @additional ||= therapist.locations.build(location_type: "additional")
      @additional.assign_attributes(raw.permit(*LOCATION_FIELDS))
      @additional.save
    end

    def additional_blank?(raw)
      %i[street_address zip city state].all? { |k| raw[k].to_s.strip.blank? }
    end
  end
end
