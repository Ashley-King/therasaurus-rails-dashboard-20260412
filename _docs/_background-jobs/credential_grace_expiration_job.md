# CredentialGraceExpirationJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 03:00 via `config/recurring.yml` (`expire_credentials_past_grace`). Also safe to enqueue manually.
**Input:** none
**Idempotent:** Yes — already-expired/revoked rows are filtered out before the update, so re-running is a no-op.

## What it does

Finds every `UserCredential` where:

- `credential_status` is `PENDING_REVIEW` or `VERIFIED`
- `grace_expires_at` is set
- `grace_expires_at` is in the past

and flips `credential_status` to `EXPIRED`.

## Why

`user_credentials` store expiration with month precision: the form writes `expiration_date = last day of the selected month`, and `UserCredential#before_save` sets `grace_expires_at = expiration_date.end_of_day + UserCredential::GRACE_PERIOD` (currently 2 weeks). This job is what flips the status once the grace window has passed — the therapist got two weeks after the month lapsed to renew, and they didn't.

## Related code

- `app/jobs/credential_grace_expiration_job.rb`
- `app/models/user_credential.rb` (`GRACE_PERIOD`, `before_save :recompute_grace_expires_at`)
- `config/recurring.yml`
