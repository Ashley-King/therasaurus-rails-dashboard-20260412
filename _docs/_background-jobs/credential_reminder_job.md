# CredentialReminderJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 09:00 via `config/recurring.yml` (`send_credential_reminders`). Also safe to enqueue manually.
**Input:** none
**Idempotent:** Yes. Each reminder writes `last_reminder_type` and `last_reminder_sent_at` so the same reminder type is not sent twice.

## What it does

Sends credential emails for verified credentials:

- First day of the expiration month: `expiration_month`
- Seven days before expiration: `expiration_week`
- First day after expiration: `grace_started`

The app stores credential expiration with month precision. A selected month is saved as the last day of that month.

## Related code

- `app/jobs/credential_reminder_job.rb`
- `app/mailers/credential_reminder_mailer.rb`
- `app/models/user_credential.rb`
- `config/recurring.yml`
