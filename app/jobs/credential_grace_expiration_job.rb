class CredentialGraceExpirationJob < ApplicationJob
  queue_as :default

  # Flips any pending_review or verified credential whose grace period has
  # elapsed to :expired. Runs daily (see config/recurring.yml). Idempotent:
  # safe to run more than once — already-expired/revoked rows are skipped.
  def perform
    UserCredential
      .where(credential_status: %w[PENDING_REVIEW VERIFIED])
      .where.not(grace_expires_at: nil)
      .where("grace_expires_at < ?", Time.current)
      .find_each do |credential|
        credential.update!(credential_status: :expired)
      end
  end
end
