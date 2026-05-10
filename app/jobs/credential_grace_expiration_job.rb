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
      .includes(therapist: :user)
      .find_each do |credential|
        unless credential.last_reminder_type == UserCredential::EXPIRED_REMINDER
          CredentialReminderMailer.with(credential: credential).expired.deliver_later
        end

        credential.update!(
          credential_status: :expired,
          last_reminder_type: UserCredential::EXPIRED_REMINDER,
          last_reminder_sent_at: Time.current
        )
      end
  end
end
