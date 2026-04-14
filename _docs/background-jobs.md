# Background Jobs

## GeocodeLocationJob

**Queue:** default (Solid Queue)
**Trigger:** Enqueued after successful account creation in `CreateAccountController#create`.
**Input:** `location_id`
**Idempotent:** Yes — safe to run multiple times, overwrites geocode fields with latest result.

### What it does

Resolves lat/lng for a location using the `zip_lookups` table with three-stage fallback:

1. **Perfect match** — zip + state + city/city_alt match. Sets `city_match_successful = true`.
2. **State + ZIP fallback** — zip + state match (first result). Sets `city_match_successful = false`.
3. **ZIP-only fallback** — zip match only (first result). Sets `city_match_successful = false`.

Prefers `city_lat`/`city_lng` over `zip_lat`/`zip_lng` when available.

If all stages fail, sets `geocode_status = "failed"` with nil lat/lng.
