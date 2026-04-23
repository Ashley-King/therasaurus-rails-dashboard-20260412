# Background Jobs

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

Flips `user_credentials.credential_status` from `PENDING_REVIEW` / `VERIFIED` to `EXPIRED` once `grace_expires_at` has passed. See [`_background-jobs/credential_grace_expiration_job.md`](./_background-jobs/credential_grace_expiration_job.md).

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

## GeocodeTargetedZipJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued by the `Geocodable` concern in an `after_commit` callback on `TherapistTargetedZip`, only when `geocode_status == "pending"`.
**Input:** `targeted_zip_id`
**Idempotent:** Yes.

Sibling of `GeocodeLocationJob`. Same three-stage `ZipLookup.geocode_with_fallback`, but `TherapistTargetedZip` has no `canonical_city` / `canonical_state` columns, so those writes are skipped. If all stages fail, sets `geocode_status = "failed"`.
