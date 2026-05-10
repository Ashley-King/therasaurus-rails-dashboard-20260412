class Location < ApplicationRecord
  include Geocodable

  belongs_to :therapist

  enum :location_type, { primary: "primary", additional: "additional" }

  validates :street_address, :city, :state, :zip, presence: true
  validate :zip_matches_country

  def full_address
    parts = [ street_address, street_address2, city, "#{state} #{zip}" ].compact_blank
    parts.join(", ")
  end

  private

  def zip_matches_country
    return if zip.blank? || therapist&.country.blank?
    return if therapist.country.accepts_postal_code?(zip)

    errors.add(:zip, :invalid_us)
  end

  def geocode_job_class
    GeocodeLocationJob
  end
end
