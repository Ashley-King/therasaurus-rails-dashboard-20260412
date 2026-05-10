class GeocodeTargetedPostalCodeJob < ApplicationJob
  queue_as :default

  def perform(targeted_postal_code_id)
    targeted = TherapistTargetedPostalCode.find_by(id: targeted_postal_code_id)
    return unless targeted

    record, city_match = ZipLookup.geocode_with_fallback(
      zip: targeted.postal_code,
      state_id: targeted.state,
      city: targeted.city
    )

    if record
      targeted.update!(
        latitude: record.city_lat || record.zip_lat,
        longitude: record.city_lng || record.zip_lng,
        city_match_successful: city_match,
        geocode_status: "ok",
        geocoded_at: Time.current
      )
    else
      targeted.update!(
        geocode_status: "failed",
        geocoded_at: Time.current
      )
    end
  end
end
