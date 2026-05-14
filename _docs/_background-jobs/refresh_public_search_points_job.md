# RefreshPublicSearchPointsJob

## Purpose

Rebuild one therapist's public search rows.

`POST /api/v1/search` reads from `public_search_points`, not from the
full therapist data model. This keeps public search fast and keeps
private fields out of the search path.

## Trigger

The job is enqueued after changes to:

- therapist public profile fields,
- user membership or banned status,
- primary and additional locations,
- targeted ZIPs,
- credential verification,
- focus specialties,
- services,
- languages,
- insurance companies.

## Behavior

The job deletes and rebuilds rows for one therapist.

If the therapist is no longer public, the table is left with no rows for
that therapist.

An eligible therapist can have up to seven rows:

- one primary location,
- one additional location,
- up to five targeted ZIPs.

Each row also stores the listing card fields, including the display
name, image key, profession, city/state line, phone visibility, session
format flags, availability flags, free-call flag, and insurance badge
flag. It also stores `credentials_verified` for the verified badge.

## Safety

The job is safe to run more than once.

It uses a per-therapist database lock so two queued refreshes for the
same therapist do not write duplicate search rows at the same time.

## Backfill

Run this after deploying the table for the first time:

```bash
bin/rails search:refresh_public_points
```
