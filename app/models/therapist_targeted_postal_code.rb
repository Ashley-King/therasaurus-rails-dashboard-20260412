class TherapistTargetedPostalCode < ApplicationRecord
  include Geocodable

  MAX_PER_THERAPIST = 5

  belongs_to :therapist

  validates :postal_code, presence: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :state,
            presence: true,
            format: { with: /\A[A-Z]{2}\z/, message: :invalid_code }
  validates :postal_code,
            uniqueness: { scope: :therapist_id, message: :taken_for_therapist }
  validate :postal_code_matches_country
  validate :within_therapist_cap, on: :create

  normalizes :postal_code, with: ->(v) { v.to_s.strip.upcase }
  normalizes :state, with: ->(v) { v.to_s.strip.upcase }

  private

  def postal_code_matches_country
    return if postal_code.blank? || therapist&.country.blank?
    return if therapist.country.accepts_postal_code?(postal_code)

    errors.add(:postal_code, :invalid_us)
  end

  def within_therapist_cap
    return unless therapist
    return if therapist.therapist_targeted_postal_codes.where.not(id: id).count < MAX_PER_THERAPIST

    errors.add(:base, :targeted_postal_code_limit, count: MAX_PER_THERAPIST)
  end

  def geocode_job_class
    GeocodeTargetedPostalCodeJob
  end
end
