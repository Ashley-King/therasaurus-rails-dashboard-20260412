class ZipLookup < ApplicationRecord
  self.table_name = "zip_lookups"

  # Three-stage fallback geocoding lookup.
  # Returns [record, city_match_successful] or [nil, false].
  def self.geocode_with_fallback(zip:, state_id:, city:)
    normalized_zip = zip.to_s.strip[0, 5]
    normalized_state = state_id.to_s.strip.upcase
    normalized_city = city.to_s.strip.downcase

    # Stage 1: Perfect match — zip + state + city (or city_alt)
    record = where(zip: normalized_zip, state_id: normalized_state)
             .where("lower(city) = :city OR lower(city_alt) = :city", city: normalized_city)
             .first
    return [ record, true ] if record

    # Stage 2: State + ZIP fallback
    record = where(zip: normalized_zip, state_id: normalized_state).first
    return [ record, false ] if record

    # Stage 3: ZIP-only fallback
    record = where(zip: normalized_zip).first
    return [ record, false ] if record

    [ nil, false ]
  end
end
