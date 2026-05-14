# Search

## Current State

Rails uses Supabase Postgres as the source of truth for therapist,
location, ZIP, and reference data.

`search.therasaurus.org` currently points to a Dockerized Meilisearch
service behind Cloudflare Tunnel. Treat this as temporary. Do not add new
Meilisearch work unless it is needed to keep the current service running
until replacement.

The Rails `/zip-search` endpoint is not Meilisearch. It reads from the
`zip_lookups` table in Supabase Postgres and returns ZIP autocomplete
results for account setup and practice location forms.

Rails also has a first-version public search API at `/api/v1/search`.
It reads from `public_search_points`, a public-search read table built
from therapist, location, targeted ZIP, credential, specialty, service,
and language data. Next.js has not been switched to it yet. Meilisearch
should stay online until the Rails endpoint is tested with realistic
traffic.

## Rails Public Search API

Route:

```text
POST /api/v1/search
```

Use a JSON body. Do not put search terms in the query string.

Supported fields:

- `zip` — required five-digit United States ZIP.
- `therapy` — optional UI key: `occupational`, `physical`, `speech`,
  `educational`, `mental_health`, `art`, or `music`.
- `profession_type` — optional direct profession type code: `OT`, `PT`,
  `SLP`, `ET`, `MH`, `AT`, or `MT`.
- `profession` — optional exact profession name.
- `verified_only` — optional boolean.
- `page` — optional page number, capped at 50.
- `order_token` — optional opaque value used for stable random ordering.

The endpoint returns the current Meilisearch-style fields needed by the
Next.js result card, plus `distance_miles`, `matched_source_type`, and
`matched_postal_code`.

## Search Rules

First version:

- Search resolves the submitted ZIP through `zip_lookups`.
- Search radius is 30 miles.
- Each therapist can match from up to seven points:
  - one primary location,
  - one additional location,
  - up to five targeted ZIPs.
- Results are deduped by therapist.
- When a therapist has several matching points, the nearest point wins.
- Directory results still require a public profile.
- Directory results still require the primary location to have working
  coordinates.
- Targeted ZIPs can make a therapist appear in nearby searches even when
  the physical location is outside the search ZIP.

## Public Search Read Table

`public_search_points` is the read table for public directory search.
It stores only fields needed by search results.

Listing fields include the display `name`, profession, profile image
key, public phone fields, city/state display line, virtual/in-person
flags, accepting-new-clients flag, waitlist flag, free-call flag, and
whether the therapist selected any insurance companies. The table also
stores `credentials_verified` so the listing can show a verified badge.

Each public therapist can have up to seven rows:

- one primary location,
- one additional location,
- up to five targeted ZIPs.

The table is refreshed by `RefreshPublicSearchPointsJob` after changes
to therapist visibility, public profile fields, locations, targeted
ZIPs, credentials, specialties, services, languages, or insurance
companies.

The refresh deletes and rebuilds the therapist's rows. It uses a
per-therapist database lock so duplicate queued refreshes do not create
duplicate rows.

To rebuild the full table after deploy or a data fix:

```bash
bin/rails search:refresh_public_points
```

RLS is enabled on the table. There is no browser read policy in this
first Rails API version. Public users read search results through
`POST /api/v1/search`.

## Stable Ordering

The Rails endpoint can order results with:

```text
order_token=<opaque random value>
```

Rails sorts matching therapists by `md5(order_token + therapist_id)`.
It does not store the token. To show the same therapist order to the
same person for 24 hours, Next.js should store a random token in a
24-hour cookie and send that token to Rails. After 24 hours, Next.js can
replace the token.

If no `order_token` is sent, Rails uses the current date. That keeps the
order stable for a day, but all visitors see the same order.

This means the Cloudflare search-order worker should not be needed once
Next.js sends `order_token` to Rails.

## Database Support

Search uses PostGIS `ST_DWithin` against a GIST expression index on
`public_search_points`.

The endpoint only reads:

- `zip_lookups`, to resolve the submitted ZIP.
- `public_search_points`, to find matching public therapists.

The original location and targeted ZIP tables also keep supporting
indexes. They are useful for refresh and fallback checks, but the public
search request does not join through the full therapist data model.

## Target State

Replace Meilisearch with Supabase-backed search.

Expected shape:

- Rails and Supabase Postgres remain the system of record.
- Search reads from the public-search read table in Supabase Postgres.
- Rails owns app writes.
- Next.js calls Rails or a controlled Supabase-backed endpoint for
  public search.
- Browser access to Supabase tables stays deny-by-default unless a
  direct browser query is truly needed and protected by narrow RLS
  policies.
- Meilisearch Docker service, tunnel route, secrets, sync jobs, and
  alerts are removed after the replacement is live.

Supabase's own docs describe Postgres full text search as a built-in
search option and recommend indexes for faster searches. Use that as the
default direction before adding another search service.

## Rate Limiting

During the transition:

- Keep Cloudflare protection on `search.therasaurus.org`.
- Keep Rails `Rack::Attack` protection on `/zip-search`.
- Keep Rails `Rack::Attack` protection on `/api/v1/search`.
- Do not depend on Meilisearch-side protection alone.

After Meilisearch is removed:

- Remove Meilisearch-specific Cloudflare rules.
- Keep Cloudflare and Rails limits for `/api/v1/search`.
- Update `_docs/_processes/rate-limiting.md` with the final search route
  and limit.

## Monitoring

During the transition:

- Meilisearch tunnel and service health are temporary checks.
- Search abuse may show up in Cloudflare before Rails sees it.

After Meilisearch is removed:

- Search traffic should show up in Rails logs or the chosen
  Supabase-backed endpoint logs.
- Better Stack should alert on search route 429s, 5xx responses, and
  slow queries if those logs exist.
- Cloudflare Security Events should remain the first place to check
  blocked traffic.

## Security Rules

- Never expose the Supabase service role key to the browser.
- Keep RLS enabled on exposed tables.
- Keep policies narrow.
- Do not put privileged database functions in exposed schemas.
- If search uses database views, make sure the view does not bypass RLS.

## Related Docs

- [`locations.md`](./locations.md) — ZIP lookup and geocoding behavior
- [`rate-limiting.md`](./rate-limiting.md) — Rails and Cloudflare limits
- [`cloudflare-rate-limiting-and-tunnel-access.md`](../_plans/cloudflare-rate-limiting-and-tunnel-access.md) — tunnel and edge plan
- Supabase full text search docs:
  https://supabase.com/docs/guides/database/full-text-search
- Supabase RLS docs:
  https://supabase.com/docs/guides/database/postgres/row-level-security
