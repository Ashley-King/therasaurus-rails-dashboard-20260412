class CredentialReminderJob < ApplicationJob
  queue_as :default

  def perform(today = Date.current)
    if today.day == 1
      send_reminder(today.end_of_month, UserCredential::EXPIRATION_MONTH_REMINDER, :expiration_month)
    end

    send_reminder(today + 7.days, UserCredential::EXPIRATION_WEEK_REMINDER, :expiration_week)
    send_reminder(today - 1.day, UserCredential::GRACE_STARTED_REMINDER, :grace_started)
  end

  private

  def send_reminder(expiration_date, reminder_type, mailer_method)
    UserCredential
      .verified
      .expiring_on(expiration_date)
      .where("last_reminder_type IS NULL OR last_reminder_type != ?", reminder_type)
      .includes(therapist: :user)
      .find_each do |credential|
        CredentialReminderMailer.with(credential: credential).public_send(mailer_method).deliver_later
        credential.update!(
          last_reminder_type: reminder_type,
          last_reminder_sent_at: Time.current
        )
      end
  end
end
