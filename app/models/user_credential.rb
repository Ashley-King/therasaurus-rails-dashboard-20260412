class UserCredential < ApplicationRecord
  belongs_to :therapist
  belongs_to :license_state, class_name: "State", optional: true
  belongs_to :credential_organization, optional: true

  enum :credential_status, {
    pending_review: "PENDING_REVIEW",
    verified: "VERIFIED",
    revoked: "REVOKED",
    expired: "EXPIRED"
  }
end
