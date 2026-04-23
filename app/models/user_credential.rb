class UserCredential < ApplicationRecord
  # How long after a credential's expiration month we give the therapist
  # to renew before the grace job flips them to :expired.
  GRACE_PERIOD = 2.weeks

  belongs_to :therapist
  belongs_to :license_state, class_name: "State", optional: true
  belongs_to :credential_organization, optional: true

  # Enforced at the DB level too via a unique index on therapist_id.
  validates :therapist_id, uniqueness: true

  enum :credential_status, {
    pending_review: "PENDING_REVIEW",
    verified: "VERIFIED",
    revoked: "REVOKED",
    expired: "EXPIRED"
  }

  before_save :recompute_grace_expires_at

  # The expiration date relevant to this credential's type. State-license
  # and supervised credentials use license_expiration_date; organization
  # credentials use organization_expiration_date.
  def expiration_date
    case credential_type
    when "state_license", "supervised" then license_expiration_date
    when "organization" then organization_expiration_date
    end
  end

  private

  def recompute_grace_expires_at
    date = expiration_date
    self.grace_expires_at = date.present? ? date.end_of_day + GRACE_PERIOD : nil
  end
end
