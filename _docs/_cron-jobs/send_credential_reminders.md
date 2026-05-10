# send_credential_reminders

**Configured in:** `config/recurring.yml`
**Schedule:** Every day at 09:00
**Runs:** `CredentialReminderJob` on the `default` queue

Sends credential reminder emails for verified credentials on the first day of the expiration month, seven days before expiration, and the first day of the two week grace period.

See [`credential_reminder_job.md`](../_background-jobs/credential_reminder_job.md) for details.
