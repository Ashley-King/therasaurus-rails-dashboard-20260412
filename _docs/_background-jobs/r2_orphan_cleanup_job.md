# R2OrphanCleanupJob

**Queue:** default (Solid Queue)
**Trigger:** Scheduled daily at 04:00 via `config/recurring.yml` (`r2_orphan_cleanup`). Also available as an Avo admin action (`Avo::Actions::RunR2OrphanCleanup`) on the UserCredential resource.
**Input:** none
**Idempotent:** Yes.

## What it does

Deletes R2 objects that have no database reference, across both buckets:

- **Profile photos** — `R2_HEADSHOTS_BUCKET_NAME`, prefix `profiles/`. In-use set is `Therapist.pluck(:practice_image_key)`.
- **Credential documents** — `R2_CREDENTIALS_BUCKET_NAME`, prefix `credentials/`. In-use set is `UserCredential.pluck(:credential_document)`.

## Safety rules

- **Age gate.** Only objects whose `LastModified` is older than `MIN_AGE` (24h) are considered. Fresh objects are ignored so a user who's mid-flow (uploaded to R2 but hasn't saved the form) never loses their file.
- **Prefix-scoped listing.** Only `profiles/` and `credentials/` keys are listed. If something ever lands elsewhere in the bucket, it's left alone.
- **Comprehensive logs.** Every delete is logged at INFO with `event=r2.cleanup.delete`, `bucket`, `key`, `last_modified`, `size`. These ship to Better Stack along with the rest of the Rails logs.

## Why the storage-format unification

Before 2026-04-19, profile photos stored the full public URL in `therapists.practice_image_url` while credentials stored just the object key. The cleanup logic needs the key to match objects, so both tables now store keys; the public URL for profile photos is computed on demand in `Therapist#practice_image_url`.

## Related code

- `app/jobs/r2_orphan_cleanup_job.rb`
- `app/avo/actions/run_r2_orphan_cleanup.rb`
- `config/recurring.yml`
- `app/models/therapist.rb` (`practice_image_url` builder method)
