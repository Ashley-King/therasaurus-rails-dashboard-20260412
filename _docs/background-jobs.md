# Background Jobs

## Production runner

Production uses Solid Queue and stores the queue tables in the normal
Supabase Postgres database. There is no separate `queue` database.

Kamal runs jobs through a dedicated `job` role with `cmd: bin/jobs`.
Jobs do not run inside Puma in production.

Workers poll once per second. This keeps database traffic low for a
low-volume Supabase-backed app.

Solid Cable and Solid Cache also use the normal app database. Their
tables are created by normal Rails migrations, not separate schema files.
RLS is enabled on the Solid tables with no browser policies.

## Pay::Webhooks::ProcessJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued by Pay after `POST /pay/webhooks/stripe` verifies
and stores a Stripe webhook.
**Input:** `Pay::Webhook`
**Idempotent:** Pay's sync work is safe to run more than once. App-side
emails and admin notifications use `stripe_webhook_receipts` so the
same Stripe event does not send the same side effect twice.

Processes Pay webhook rows after Stripe has already received a `200`
response. `config/initializers/pay_webhook_job_retries.rb` retries
transient Stripe, database, and network failures. Bad input still fails
normally so it reaches the configured error reporting path.

## R2OrphanCleanupJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 04:00 via `config/recurring.yml` (`r2_orphan_cleanup`). Also available as an Avo admin action on the UserCredential resource.
**Input:** none
**Idempotent:** Yes.

Deletes R2 objects older than 24h with no DB reference, across the `profiles/` (headshots bucket) and `credentials/` (ptd-credentials bucket) prefixes. Logs every deleted key. See [`_background-jobs/r2_orphan_cleanup_job.md`](./_background-jobs/r2_orphan_cleanup_job.md).

## CredentialGraceExpirationJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 03:00 via `config/recurring.yml` (`expire_credentials_past_grace`).
**Input:** none
**Idempotent:** Yes.

Flips `user_credentials.credential_status` from `PENDING_REVIEW` / `VERIFIED` to `EXPIRED` once `grace_expires_at` has passed, then sends the expired credential email. See [`_background-jobs/credential_grace_expiration_job.md`](./_background-jobs/credential_grace_expiration_job.md).

## CredentialReminderJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 09:00 via `config/recurring.yml` (`send_credential_reminders`).
**Input:** none
**Idempotent:** Yes.

Sends credential emails for verified credentials on the first day of the expiration month, seven days before expiration, and the first day of the two week grace period. See [`_background-jobs/credential_reminder_job.md`](./_background-jobs/credential_reminder_job.md).

## GeocodeLocationJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued by the `Geocodable` concern (`app/models/concerns/geocodable.rb`) in an `after_commit` callback on `Location`, and only when `geocode_status == "pending"` — i.e. the synchronous resolve couldn't match the address against `zip_lookups`. For almost every save (combobox pick or zip_lookups-backed write-in), this job never runs.
**Input:** `location_id`
**Idempotent:** Yes — safe to run multiple times, overwrites geocode fields with latest result.

### What it does

Falls back to the three-stage `ZipLookup.geocode_with_fallback` match a second time (in case a new `zip_lookups` row arrived between save and job run) and writes the result:

1. **Perfect match** — zip + state + city/city_alt match. Sets `city_match_successful = true`.
2. **State + ZIP fallback** — zip + state match (first result). Sets `city_match_successful = false`.
3. **ZIP-only fallback** — zip match only (first result). Sets `city_match_successful = false`.

Prefers `city_lat`/`city_lng` over `zip_lat`/`zip_lng` when available. Sets `canonical_city` / `canonical_state` from the matched row.

If all stages still fail, sets `geocode_status = "failed"` with nil lat/lng.

See [`_processes/locations.md`](./_processes/locations.md) for the full save-time + async flow.

## GeocodeTargetedPostalCodeJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued by the `Geocodable` concern in an `after_commit` callback on `TherapistTargetedPostalCode`, only when `geocode_status == "pending"`.
**Input:** `targeted_postal_code_id`
**Idempotent:** Yes.

Sibling of `GeocodeLocationJob`. Same three-stage `ZipLookup.geocode_with_fallback`, but `TherapistTargetedPostalCode` has no `canonical_city` / `canonical_state` columns, so those writes are skipped. If all stages fail, sets `geocode_status = "failed"`.

## RefreshPublicSearchPointsJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued after public-search inputs change on `Therapist`,
`User`, `Location`, `TherapistTargetedPostalCode`, `UserCredential`,
`PracticeSpecialty`, `PracticeService`, `PracticeLanguage`, and
`PracticeInsuranceCompany`.
**Input:** `therapist_id`
**Idempotent:** Yes.

Rebuilds one therapist's rows in `public_search_points`, the public
search read table used by `POST /api/v1/search`.

Each eligible therapist can have one primary location row, one
additional location row, and up to five targeted ZIP rows. Duplicate
queued refreshes are serialized with a per-therapist database lock.

See [`_background-jobs/refresh_public_search_points_job.md`](./_background-jobs/refresh_public_search_points_job.md).
