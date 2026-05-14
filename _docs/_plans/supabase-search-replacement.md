# Supabase Search Replacement Plan

**Date:** 2026-05-10
**Status:** Draft

## Goal

Remove Meilisearch and use Supabase Postgres for search instead.

The finished system should be simpler:

- One database stores therapist data and supports search.
- No Meilisearch Docker service.
- No Meilisearch tunnel route.
- No Meilisearch sync jobs or reindex work.
- Search remains fast enough for launch traffic.
- Public search stays protected by Cloudflare and app-side limits.

## Assumptions

- Meilisearch is still running today behind Cloudflare Tunnel.
- Supabase Postgres is already the source of truth.
- Rails owns app writes.
- Next.js owns the public search UI.
- Search should not expose private therapist fields.
- Direct browser access to Supabase should be avoided unless it is
  clearly simpler and protected by narrow RLS policies.

## Phase 1: Inventory Current Meilisearch Usage

### Scope

Find every place that depends on Meilisearch before removing it.

### Why this phase comes now

Removing a search service safely starts with knowing what still calls it.

### Main changes

- Check the Next.js app for direct calls to `search.therasaurus.org`.
- Check Docker and Cloudflare Tunnel config for the Meilisearch service.
- Check Rails for Meilisearch jobs, credentials, webhooks, and alerts.
- Check Better Stack and Discord alerts for search-service references.
- List every environment variable and secret that belongs only to
  Meilisearch.

### Risks or edge cases

- Next.js may call Meilisearch directly from the browser.
- A hidden admin or script may still use Meilisearch for testing.
- Old Cloudflare rules can stay active after the service is gone.

### Validation

- A written inventory exists before code or infrastructure is removed.
- Every Meilisearch dependency has an owner and removal step.

### Temporary inconsistency

None.

## Phase 2: Choose The Supabase Search Path

### Scope

Pick the first Supabase-backed search shape.

### Why this phase comes now

The app should use one simple path first. Do not build both a direct
Supabase browser path and a Rails API path unless there is a clear need.

### Main changes

Chosen first-version path:

- Rails exposes the public search endpoint.
- Rails queries the `public_search_points` read table in Supabase
  Postgres.
- Next.js calls Rails.
- Cloudflare rate limits the public search route.
- Rails logs search failures and slow requests.

Only choose direct Supabase browser search if it is clearly simpler and
the RLS policy can be kept narrow.

Use the public-search read table first. Add generated search columns,
GIN indexes, or full text search only when needed for speed or relevance.
Avoid adding another external search service during this replacement.

### Risks or edge cases

- Direct browser queries can expose more data than intended if RLS is
  wrong.
- A Rails API path adds one more request hop from Next.js.
- Search relevance may be weaker than Meilisearch at first.

### Validation

- The chosen path lists the public route, query inputs, returned fields,
  and rate limits.
- Private therapist fields are not returned.
- The first query plan uses indexes for the common searches.

### Temporary inconsistency

Meilisearch will still serve production search while the Supabase-backed
path is being built.

## Phase 3: Build Supabase-Backed Search

### Scope

Build the smallest useful replacement for the current public search.

### Why this phase comes now

This proves Supabase can handle the common search path before the old
service is removed.

### Main changes

- Add or update database indexes for search.
- Add the `public_search_points` read table.
- Add a clear search query object in Rails.
- Add a public search endpoint if Rails is the chosen API.
- Return only fields needed by the public search UI.
- Add request logging that does not store sensitive search details.
- Do not add tests for this first pass unless a specific risk requires
  them.

### Risks or edge cases

- Unindexed search can make Supabase slow.
- Pagination and sorting can be inconsistent if the query order is not
  deterministic.
- Search terms may include city, specialty, service, and age-group words
  in one input.

### Validation

- Common searches return expected therapists.
- Empty and invalid searches are handled.
- Query time is acceptable with realistic data.
- RLS stays enabled on exposed tables.
- The service role key is not used in browser code.

### Temporary inconsistency

The app will have two search systems until Next.js switches over.

## Phase 4: Switch Next.js And Cloudflare

### Scope

Move public search traffic from Meilisearch to the Supabase-backed path.

### Why this phase comes now

The replacement must receive real traffic before the old service is
removed.

### Main changes

- Update Next.js to call the new search path.
- Keep Meilisearch running during the first switch.
- Add Cloudflare rules for the new search path in Log mode first.
- Add app-side rate limiting if Rails exposes the route.
- Watch Cloudflare, Rails logs, and host metrics during rollout.

### Risks or edge cases

- Cached frontend code may call the old Meilisearch route for a while.
- Search traffic can spike if the UI debounce breaks.
- Cloudflare can block real users if enforcement starts too soon.

### Validation

- Next.js search works without Meilisearch.
- Meilisearch request volume drops near zero.
- No new 5xx spike appears.
- Cloudflare events are clean for normal search traffic.

### Temporary inconsistency

Meilisearch remains available as a short rollback path.

## Phase 5: Remove Meilisearch

### Scope

Delete the old service and its docs.

### Why this phase comes now

Only remove the old service after the Supabase-backed path has handled
real traffic.

### Main changes

- Remove Meilisearch Docker service.
- Remove Meilisearch Cloudflare Tunnel route.
- Remove Meilisearch secrets and API keys.
- Remove Meilisearch sync jobs and code.
- Remove `SEARCH_INDEX_SERVICE_WEBHOOK` if nothing else uses it.
- Remove or rename `:search_index_service` notifications.
- Update `_docs/_processes/search.md`.
- Update `_docs/_processes/rate-limiting.md`.
- Update `_docs/_plans/cloudflare-rate-limiting-and-tunnel-access.md`.

### Risks or edge cases

- A stale client may still call `search.therasaurus.org`.
- An old deploy script may expect Meilisearch secrets to exist.
- Search alerts may go quiet if they are removed before replacement
  alerts are active.

### Validation

- `search.therasaurus.org` no longer points to Meilisearch.
- The Docker service is gone.
- No Rails or Next.js code references Meilisearch.
- Search still works through the Supabase-backed path.
- Monitoring alerts are still active.

### Temporary inconsistency

None after this phase is complete.

## Risks

- Supabase search may need better indexes before it is fast enough.
- Search relevance may need tuning after real users search.
- Direct Supabase browser queries are risky if policies are too broad.
- The old Meilisearch tunnel can keep receiving traffic if DNS or
  Cloudflare cleanup is missed.

## Open Questions

- Will Next.js call Rails permanently, or move to direct Supabase reads
  later?
- What exact search fields are needed for launch?
- Is `search.therasaurus.org` reused for the new path or retired?
- What traffic level should trigger a Cloudflare search alert?
- Should the `:search_index_service` notification channel be removed or
  renamed after the replacement?

## Official Docs Checked

- Supabase full text search:
  https://supabase.com/docs/guides/database/full-text-search
- Supabase row level security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
