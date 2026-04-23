class ZipLookup < ApplicationRecord
  self.table_name = "zip_lookups"

  # Autocomplete results for a digit prefix. Rows where city_alt is set (e.g.
  # San Buenaventura / Ventura) produce two separate options — city and
  # city_alt — so therapists searching by the familiar name still find it.
  #
  # `query` must already be validated as digits-only by the caller; we guard
  # once more here and bail early on anything else. This is load-bearing for
  # the safe interpolation below.
  def self.prefix_search(query, limit: 10)
    digits = query.to_s
    return [] unless digits.match?(/\A\d{1,5}\z/)

    limit_i = [ limit.to_i, 1 ].max
    pattern = "#{digits}%"

    sql = <<~SQL.squish
      WITH candidates AS (
        SELECT zip, city AS name, state_id,
               COALESCE(zip_lat, city_lat) AS lat,
               COALESCE(zip_lng, city_lng) AS lng
        FROM zip_lookups
        WHERE zip LIKE '#{pattern}'
        UNION ALL
        SELECT zip, city_alt AS name, state_id,
               COALESCE(zip_lat, city_lat) AS lat,
               COALESCE(zip_lng, city_lng) AS lng
        FROM zip_lookups
        WHERE zip LIKE '#{pattern}'
          AND city_alt IS NOT NULL
          AND city_alt <> ''
      )
      SELECT DISTINCT ON (zip, name, state_id)
             zip, name AS city, state_id, lat, lng
      FROM candidates
      ORDER BY zip, name, state_id
      LIMIT #{limit_i}
    SQL

    connection.select_all(sql).to_a
  end

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
