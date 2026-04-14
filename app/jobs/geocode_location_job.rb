class GeocodeLocationJob < ApplicationJob
  queue_as :default

  def perform(location_id)
    location = Location.find_by(id: location_id)
    return unless location

    record, city_match = ZipLookup.geocode_with_fallback(
      zip: location.zip,
      state_id: location.state,
      city: location.city
    )

    if record
      location.update!(
        latitude: record.city_lat || record.zip_lat,
        longitude: record.city_lng || record.zip_lng,
        canonical_city: record.city,
        canonical_state: record.state_id,
        city_match_successful: city_match,
        geocode_status: "ok",
        geocoded_at: Time.current
      )
    else
      location.update!(
        geocode_status: "failed",
        geocoded_at: Time.current
      )
    end
  end
end
