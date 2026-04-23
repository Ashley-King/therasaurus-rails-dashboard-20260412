# expire_credentials_past_grace

**Configured in:** `config/recurring.yml`
**Schedule:** Every day at 03:00
**Runs:** `CredentialGraceExpirationJob` on the `default` queue

Transitions `user_credentials.credential_status` from `PENDING_REVIEW` / `VERIFIED` to `EXPIRED` once `grace_expires_at` has passed.

`grace_expires_at` is computed on save as `expiration_date.end_of_day + UserCredential::GRACE_PERIOD` (2 weeks). See [`credential_grace_expiration_job.md`](../_background-jobs/credential_grace_expiration_job.md) for details.
