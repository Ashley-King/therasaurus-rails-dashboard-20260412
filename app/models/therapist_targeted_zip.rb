class TherapistTargetedZip < ApplicationRecord
  include Geocodable

  MAX_PER_THERAPIST = 5

  belongs_to :therapist

  validates :zip, presence: true, format: { with: /\A\d{5}\z/, message: "must be 5 digits" }
  validates :city, presence: true, length: { maximum: 100 }
  validates :state, presence: true, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter code" }
  validates :zip, uniqueness: { scope: :therapist_id, message: "already added for this therapist" }
  validate :within_therapist_cap, on: :create

  normalizes :state, with: ->(v) { v.to_s.strip.upcase }

  private

  def within_therapist_cap
    return unless therapist
    return if therapist.therapist_targeted_zips.where.not(id: id).count < MAX_PER_THERAPIST

    errors.add(:base, "You can save at most #{MAX_PER_THERAPIST} targeted ZIPs")
  end

  def geocode_job_class
    GeocodeTargetedZipJob
  end
end
