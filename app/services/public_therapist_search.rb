class PublicTherapistSearch
  PAGE_SIZE = 20
  MAX_PAGE = 50
  RADIUS_MILES = 30
  METERS_PER_MILE = 1609.344
  MAX_ORDER_TOKEN_LENGTH = 128

  THERAPY_TO_PROFESSION_TYPE = {
    "occupational" => "OT",
    "physical" => "PT",
    "speech" => "SLP",
    "educational" => "ET",
    "mental_health" => "MH",
    "art" => "AT",
    "music" => "MT"
  }.freeze

  VALID_PROFESSION_TYPES = THERAPY_TO_PROFESSION_TYPE.values.to_set.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(zip:, therapy: nil, page: nil, profession_type: nil, profession_name: nil, verified_only: nil, order_token: nil)
    @zip = zip.to_s.strip
    @therapy = therapy.to_s.strip
    @page = coerce_page(page)
    @profession_type = normalize_profession_type(profession_type)
    @profession_name = profession_name.to_s.strip
    @verified_only = ActiveModel::Type::Boolean.new.cast(verified_only)
    @order_token = normalize_order_token(order_token)
  end

  def call
    return invalid_zip_result unless valid_zip?

    center = zip_center
    return empty_result(message: "No therapists match that search.") unless center

    rows = search_rows(center)
    hits = rows.map { |row| serialize_row(row) }
    total = rows.first ? rows.first["total_count"].to_i : 0

    {
      ok: true,
      page: @page,
      pageSize: PAGE_SIZE,
      radiusMiles: RADIUS_MILES,
      total: total,
      hits: hits
    }
  end

  private

  attr_reader :zip

  def valid_zip?
    zip.match?(/\A\d{5}\z/)
  end

  def invalid_zip_result
    { ok: false, error: "Invalid ZIP" }
  end

  def empty_result(message: nil)
    {
      ok: true,
      page: @page,
      pageSize: PAGE_SIZE,
      radiusMiles: RADIUS_MILES,
      total: 0,
      hits: [],
      message: message
    }.compact
  end

  def zip_center
    ZipLookup
      .where(zip: zip)
      .where("COALESCE(zip_lat, city_lat) IS NOT NULL")
      .where("COALESCE(zip_lng, city_lng) IS NOT NULL")
      .order(:id)
      .pick(Arel.sql("COALESCE(zip_lat, city_lat)"), Arel.sql("COALESCE(zip_lng, city_lng)"))
  end

  def search_rows(center)
    latitude, longitude = center
    sql = ActiveRecord::Base.sanitize_sql_array(
      [
        search_sql,
        {
          latitude: latitude,
          longitude: longitude,
          radius_meters: RADIUS_MILES * METERS_PER_MILE,
          order_token: @order_token,
          limit: PAGE_SIZE,
          offset: (@page - 1) * PAGE_SIZE,
          profession_type: @profession_type,
          profession_name: @profession_name
        }
      ]
    )

    ActiveRecord::Base.connection.select_all(sql)
  end

  def search_sql
    <<~SQL.squish
      WITH center AS (
        SELECT ST_SetSRID(ST_MakePoint(:longitude::double precision, :latitude::double precision), 4326)::geography AS geog
      ),
      matched_points AS (
        SELECT
          public_search_points.*,
          ST_Distance(
            ST_SetSRID(ST_MakePoint(
              public_search_points.longitude::double precision,
              public_search_points.latitude::double precision
            ), 4326)::geography,
            center.geog
          ) / #{METERS_PER_MILE} AS distance_miles
        FROM public_search_points
        CROSS JOIN center
        WHERE 1 = 1
          #{profession_filter_sql}
          #{verified_filter_sql}
          AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(
              public_search_points.longitude::double precision,
              public_search_points.latitude::double precision
            ), 4326)::geography,
            center.geog,
            :radius_meters
          )
      ),
      nearest_point_per_therapist AS (
        SELECT DISTINCT ON (therapist_id)
          *
        FROM matched_points
        ORDER BY therapist_id, distance_miles ASC, source_rank ASC, source_id ASC
      )
      SELECT
        nearest_point_per_therapist.*,
        count(*) OVER() AS total_count
      FROM nearest_point_per_therapist
      ORDER BY md5(:order_token || ':' || therapist_id::text), therapist_id
      LIMIT :limit
      OFFSET :offset
    SQL
  end

  def profession_filter_sql
    return "AND public_search_points.profession_type = :profession_type" if @profession_type.present?
    return "AND lower(public_search_points.profession_name) = lower(:profession_name)" if @profession_name.present?

    therapy_type = THERAPY_TO_PROFESSION_TYPE[@therapy]
    return "" unless therapy_type

    @profession_type = therapy_type
    "AND public_search_points.profession_type = :profession_type"
  end

  def verified_filter_sql
    return "" unless @verified_only

    "AND public_search_points.credentials_verified IS TRUE"
  end

  def serialize_row(row)
    practice_image_url = practice_image_url_for(row["practice_image_key"])
    location_id = row["source_type"] == "targeted_postal_code" ? nil : row["source_id"]

    hit = {
      id: row["therapist_id"],
      therapist_id: row["therapist_id"],
      unique_id: row["unique_id"],
      location_id: location_id,
      location_type: row["source_type"],
      location_line: row["location_line"].presence || city_state(row),
      user_role: row["membership_status"],
      is_public: true,
      name: row["name"],
      show_phone_number: row["show_phone_number"],
      profession_name: row["profession_name"],
      profession_type: row["profession_type"],
      full_address: nil,
      city: row["city"],
      state: row["state"],
      zip: row["postal_code"],
      profile_slug: row["profile_slug"],
      practice_name: row["practice_name"],
      use_practice_name: row["use_practice_name"],
      practice_image_url: practice_image_url,
      practice_description: row["practice_description"],
      first_name: row["first_name"],
      last_name: row["last_name"],
      credentials: row["credentials"],
      accepting_new_clients: row["accepting_new_clients"],
      has_waitlist: row["has_waitlist"],
      accepts_insurance: row["accepts_insurance"],
      free_phone_call: row["free_phone_call"],
      virtual: row["virtual"],
      in_person: row["in_person"],
      specialties: parse_json_array(row["specialties"]),
      services: parse_json_array(row["services"]),
      languages: parse_json_array(row["languages"]),
      has_geo: true,
      geocode_status: "ok",
      credentials_verified: row["credentials_verified"],
      verified: row["credentials_verified"],
      distance_miles: row["distance_miles"].to_f.round(1),
      matched_source_type: row["source_type"],
      matched_postal_code: row["postal_code"],
      indexed_at: Time.current.utc.iso8601,
      _geo: {
        lat: row["latitude"].to_f,
        lng: row["longitude"].to_f
      }
    }

    if row["show_phone_number"]
      hit[:phone_number] = row["phone_number"]
      hit[:phone_ext] = row["phone_ext"]
    end

    hit
  end

  def parse_json_array(value)
    case value
    when Array
      value
    when String
      JSON.parse(value)
    else
      []
    end
  rescue JSON::ParserError
    []
  end

  def city_state(row)
    [ row["city"], row["state"] ].compact_blank.join(", ")
  end

  def practice_image_url_for(key)
    return nil if key.blank?

    base = Rails.application.credentials.fetch(:R2_PUBLIC_URL).to_s.chomp("/")
    "#{base}/#{key}"
  end

  def coerce_page(value)
    page = value.to_i
    page = 1 if page < 1
    [ page, MAX_PAGE ].min
  end

  def normalize_profession_type(value)
    type = value.to_s.strip.upcase
    VALID_PROFESSION_TYPES.include?(type) ? type : nil
  end

  def normalize_order_token(value)
    token = value.to_s.strip
    token = Date.current.iso8601 if token.blank?
    token.first(MAX_ORDER_TOKEN_LENGTH)
  end
end
