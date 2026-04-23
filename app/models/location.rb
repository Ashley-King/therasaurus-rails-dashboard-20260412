class Location < ApplicationRecord
  include Geocodable

  belongs_to :therapist

  enum :location_type, { primary: "primary", additional: "additional" }

  validates :street_address, :city, :state, :zip, presence: true

  def full_address
    parts = [ street_address, street_address2, city, "#{state} #{zip}" ].compact_blank
    parts.join(", ")
  end

  private

  def geocode_job_class
    GeocodeLocationJob
  end
end
