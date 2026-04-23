# r2_orphan_cleanup

**Configured in:** `config/recurring.yml`
**Schedule:** Every day at 04:00 (sits after the 03:00 `expire_credentials_past_grace` job so the statuses are current before we scan storage).
**Runs:** `R2OrphanCleanupJob` on the `default` queue.

Deletes R2 objects older than 24h that have no DB reference, across the `profiles/` and `credentials/` prefixes in the headshots and ptd-credentials buckets. See [`r2_orphan_cleanup_job.md`](../_background-jobs/r2_orphan_cleanup_job.md) for safety rules.
