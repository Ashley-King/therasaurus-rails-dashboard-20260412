# Shared geocoding hooks for records that carry a US address (ZIP + city +
# state + lat/lng + geocode_status). Including this module wires up:
#
#   - a before_save that resolves lat/lng from ZipLookup when the address
#     changes (or trusts values the caller already supplied, e.g. filled by
#     the ZIP combobox).
#   - an after_commit that enqueues a background geocoding job when the
#     sync resolve couldn't find a match and status stays "pending".
#
# Including models must implement #geocode_job_class, returning the ActiveJob
# class used for the background retry.
module Geocodable
  extend ActiveSupport::Concern

  included do
    before_save :resolve_geocode, if: :address_changed_or_unresolved?
    after_commit :enqueue_geocode_if_pending, on: [ :create, :update ]
  end

  private

  def address_changed_or_unresolved?
    new_record? ||
      zip_changed? || city_changed? || state_changed? ||
      geocode_status != "ok"
  end

  def resolve_geocode
    if latitude.present? && longitude.present?
      self.geocode_status = "ok"
      self.geocoded_at = Time.current
      return
    end

    record, match = ZipLookup.geocode_with_fallback(
      zip: zip, state_id: state, city: city
    )

    if record
      self.latitude = record.city_lat || record.zip_lat
      self.longitude = record.city_lng || record.zip_lng
      self.city_match_successful = match
      self.canonical_city = record.city if has_attribute?(:canonical_city)
      self.canonical_state = record.state_id if has_attribute?(:canonical_state)
      self.geocode_status = "ok"
      self.geocoded_at = Time.current
    else
      self.geocode_status = "pending"
    end
  end

  def enqueue_geocode_if_pending
    geocode_job_class.perform_later(id) if geocode_status == "pending"
  end

  def geocode_job_class
    raise NotImplementedError, "#{self.class.name} must implement #geocode_job_class"
  end
end
