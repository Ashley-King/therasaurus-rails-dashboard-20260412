require "digest"

class PublicSearchPointRefresh
  PUBLIC_MEMBERSHIP_STATUSES = %w[trialing_member pro_member].freeze
  SOURCE_TYPES = {
    primary: "primary",
    additional: "additional",
    targeted_postal_code: "targeted_postal_code"
  }.freeze

  def self.call(therapist_id)
    new(therapist_id).call
  end

  def self.rebuild_all
    Therapist.find_each { |therapist| call(therapist.id) }
  end

  def initialize(therapist_id)
    @therapist_id = therapist_id
  end

  def call
    PublicSearchPoint.transaction do
      lock_therapist_refresh
      PublicSearchPoint.where(therapist_id: @therapist_id).delete_all

      if eligible?
        rows = search_point_rows
        PublicSearchPoint.insert_all!(rows) if rows.any?
      end
    end
  end

  private

  def lock_therapist_refresh
    lock_id = Digest::SHA256.hexdigest(@therapist_id.to_s).first(15).to_i(16)

    ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
  end

  def therapist
    @therapist ||= Therapist
      .includes(:user, { profession: :profession_type })
      .find_by(id: @therapist_id)
  end

  def eligible?
    return false unless therapist
    return false unless therapist.unique_id.present? && therapist.profile_slug.present?
    return false unless therapist.user && PUBLIC_MEMBERSHIP_STATUSES.include?(therapist.user.membership_status)
    return false if therapist.user.is_banned?

    valid_point?(primary_location)
  end

  def search_point_rows
    now = Time.current
    base = base_attributes(now)

    physical_location_rows(base, now) + targeted_postal_code_rows(base, now)
  end

  def physical_location_rows(base, now)
    locations.filter_map do |location|
      next unless valid_point?(location)

      base.merge(
        source_id: location.id,
        source_type: location.location_type,
        source_rank: location.primary? ? 0 : 1,
        city: location.city,
        state: location.state,
        postal_code: location.zip,
        latitude: location.latitude,
        longitude: location.longitude,
        created_at: now,
        updated_at: now
      )
    end
  end

  def targeted_postal_code_rows(base, now)
    targeted_postal_codes.filter_map do |targeted|
      next unless valid_point?(targeted)

      base.merge(
        source_id: targeted.id,
        source_type: SOURCE_TYPES.fetch(:targeted_postal_code),
        source_rank: 2,
        city: targeted.city,
        state: targeted.state,
        postal_code: targeted.postal_code,
        latitude: targeted.latitude,
        longitude: targeted.longitude,
        created_at: now,
        updated_at: now
      )
    end
  end

  def base_attributes(now)
    {
      therapist_id: therapist.id,
      unique_id: therapist.unique_id,
      profile_slug: therapist.profile_slug,
      membership_status: therapist.user.membership_status,
      name: listing_name,
      profession_name: therapist.profession.name,
      profession_type: therapist.profession.profession_type&.name,
      location_line: location_line,
      show_phone_number: therapist.show_phone_number?,
      phone_number: therapist.show_phone_number? ? therapist.phone_number : nil,
      phone_ext: therapist.show_phone_number? ? therapist.phone_ext : nil,
      practice_name: therapist.practice_name,
      use_practice_name: therapist.use_practice_name?,
      practice_image_key: therapist.practice_image_key,
      practice_description: therapist.practice_description,
      first_name: therapist.first_name,
      last_name: therapist.last_name,
      credentials: therapist.credentials,
      accepting_new_clients: therapist.accepting_new_clients?,
      has_waitlist: therapist.has_waitlist?,
      accepts_insurance: accepts_insurance?,
      free_phone_call: therapist.free_phone_call?,
      virtual: therapist.virtual?,
      in_person: therapist.in_person?,
      specialties: focus_specialty_names,
      services: service_names,
      languages: language_names,
      credentials_verified: credentials_verified?,
      refreshed_at: now
    }
  end

  def listing_name
    return therapist.practice_name if therapist.use_practice_name? && therapist.practice_name.present?

    [ therapist.first_name, therapist.last_name, therapist.credentials ].compact_blank.join(" ")
  end

  def primary_location
    @primary_location ||= locations.find(&:primary?)
  end

  def locations
    @locations ||= therapist.locations
      .where(location_type: [ SOURCE_TYPES.fetch(:primary), SOURCE_TYPES.fetch(:additional) ])
      .order(Arel.sql("CASE location_type WHEN 'primary' THEN 0 ELSE 1 END"))
      .to_a
  end

  def targeted_postal_codes
    @targeted_postal_codes ||= therapist.therapist_targeted_postal_codes.order(:created_at).to_a
  end

  def valid_point?(record)
    return false unless record
    return false unless record.geocode_status == "ok"
    return false if record.latitude.blank? || record.longitude.blank?

    latitude = record.latitude.to_d
    longitude = record.longitude.to_d
    latitude.between?(-90, 90) && longitude.between?(-180, 180) && !(latitude.zero? && longitude.zero?)
  end

  def location_line
    locations
      .select { |location| valid_point?(location) }
      .map { |location| [ location.city, location.state ].compact_blank.join(", ") }
      .uniq
      .first(2)
      .join(" | ")
      .presence
  end

  def focus_specialty_names
    PracticeSpecialty
      .joins(:specialty)
      .where(therapist_id: therapist.id, is_focus: true)
      .distinct
      .order("specialties.name")
      .pluck("specialties.name")
  end

  def service_names
    therapist.services.distinct.order(:name).pluck(:name)
  end

  def accepts_insurance?
    therapist.practice_insurance_companies.exists?
  end

  def language_names
    therapist.languages.distinct.order(:name).pluck(:name)
  end

  def credentials_verified?
    therapist.user_credential&.verified? || false
  end
end
