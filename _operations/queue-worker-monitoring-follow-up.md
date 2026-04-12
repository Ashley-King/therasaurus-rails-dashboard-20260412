# Queue Worker Monitoring

Created: 2026-04-04

## Why this note exists

The app now has a dedicated health check for the transactional email queue.

Use `GET /up/mailers-queue` with an external uptime check.

That endpoint returns `503` when:

- no Solid Queue worker has a fresh heartbeat
- the `mailers` queue has a ready job that has been waiting too long

## What changed

- The app checks `solid_queue_processes` for fresh `Worker` heartbeats.
- The app checks `solid_queue_ready_executions` for stale `mailers` jobs.
- The app exposes that state through one small Rails endpoint instead of another background job.

## Remaining setup

- Create or update the external uptime check that hits `GET /up/mailers-queue`.
- Point alerts from that check to the place you want human attention to go.
