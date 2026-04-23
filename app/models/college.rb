class College < ApplicationRecord
  STATUSES = %w[approved pending rejected].freeze
  NAME_MAX_LENGTH = 120

  has_many :therapist_education, class_name: "TherapistEducation", dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :status, inclusion: { in: STATUSES }

  scope :approved, -> { where(status: "approved") }
  scope :visible_to, ->(therapist) {
    where("status = ? OR (status = ? AND submitted_by_therapist_id = ?)",
          "approved", "pending", therapist.id)
  }

  before_validation :normalize_name

  def pending?
    status == "pending"
  end

  # Case-insensitive find-or-create. Returns an existing row (approved or
  # pending) when a match exists, otherwise creates a new pending row.
  def self.find_or_submit(name:, therapist:)
    normalized = name.to_s.strip.gsub(/\s+/, " ")
    return nil if normalized.blank?

    existing = where("lower(name) = ?", normalized.downcase).first
    return existing if existing

    create(
      name: normalized,
      status: "pending",
      submitted_by_therapist_id: therapist.id
    )
  end

  private

  def normalize_name
    self.name = name.to_s.strip.gsub(/\s+/, " ") if name.present?
  end
end
