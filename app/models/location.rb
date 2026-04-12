class Location < ApplicationRecord
  belongs_to :therapist

  enum :location_type, { primary: "primary", alternate: "alternate" }

  validates :street_address, :city, :state, :zip, presence: true

  before_save :geocode_from_zip, if: :zip_changed?

  def full_address
    parts = [street_address, street_address2, city, "#{state} #{zip}"].compact_blank
    parts.join(", ")
  end

  private

  def zip_changed?
    zip_previously_changed? || new_record?
  end

  def geocode_from_zip
    lookup = ZipLookup.geocode(zip: zip, state_id: state)
    return unless lookup

    self.latitude = lookup.zip_lat
    self.longitude = lookup.zip_lng
    self.canonical_city = lookup.city
    self.canonical_state = lookup.state_name
    self.city_match_successful = true
    self.geocode_status = "completed"
    self.geocoded_at = Time.current
  end
end
