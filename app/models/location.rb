class Location < ApplicationRecord
  belongs_to :therapist

  enum :location_type, { primary: "primary", alternate: "alternate" }

  validates :street_address, :city, :state, :zip, presence: true

  def full_address
    parts = [ street_address, street_address2, city, "#{state} #{zip}" ].compact_blank
    parts.join(", ")
  end
end
