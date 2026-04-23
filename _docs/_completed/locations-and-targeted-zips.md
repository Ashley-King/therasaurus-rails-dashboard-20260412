# Locations + Targeted ZIPs Plan

**Date:** 2026-04-21
**Status:** Implemented 2026-04-22. See [`_processes/locations.md`](../_processes/locations.md) for current behavior. Notable deviations from this plan: geocoding logic moved to a `Geocodable` model concern (not one-off controller code); ZIP combobox UX uses three states (empty / selected / manual) with a separate manual-entry section rather than the plan's "one set of city/state/zip inputs with suggestions that populate them" model.

## Overview

Replace the read-only placeholders on `/your-practice/locations` with an editable flow that supports:

- **Primary location** — always exists (created during `/create-account`). Editable here.
- **Additional location** — optional second office (up to 1).
- **Targeted ZIPs** — up to 5 `(city, state, zip)` tuples the therapist wants to appear in search results for, even without a physical address there.

The feature hinges on a ZIP-code autocomplete backed by the existing `zip_lookups` table (39,128 unique ZIPs, 131,462 rows). A match from the autocomplete fills `city`, `state`, `zip`, and lat/lng synchronously — no background geocoding needed for the 99% case. Manual write-ins fall back to `ZipLookup.geocode_with_fallback` (already built) and, if still unresolved, to the existing `GeocodeLocationJob`.

---

## Goals

- Make it possible for a therapist to finish onboarding and have their profile geocoded **before** the trial clock starts.
- Keep the autocomplete purely assistive — never block a submit if the typed ZIP isn't in `zip_lookups`.
- Avoid a second "manual vs. autocomplete" mode toggle. One set of city/state/zip inputs, with suggestions that populate them when picked.
- Keep the frontend-facing search performant even as targeted ZIPs multiply.

## Non-goals

- Street-level geocoding. We use the ZIP/city centroid; it's accurate enough for radius search and respects privacy for therapists who hide their street address.
- Multi-tenant admin tooling for locations. Single-developer scope.
- International addresses (already US-only per existing `Country` constraint).

---

## The Create-Account Decision

**Question:** When does a therapist enter their primary address — at account creation, or later? And how do we guarantee geocoding is done before the profile goes live?

**Decision:** **Keep primary address in `/create-account`**, but tighten the flow so geocoding finishes *synchronously* for nearly every signup.

**Why this works:**

| Path | % of signups | Geocode timing |
|---|---|---|
| Picks ZIP from autocomplete | ~95% | **Synchronous** — lat/lng copied from `zip_lookups` at save time |
| Types ZIP manually, matches `zip_lookups` via `ZipLookup.geocode_with_fallback` in the controller | ~4% | **Synchronous** — controller does the match before redirect |
| Manual entry, no match in `zip_lookups` | <1% | Falls back to `GeocodeLocationJob` (existing), which may queue an external geocoder later if we ever add one |

With the autocomplete in front of the ZIP field, the background job becomes a safety net, not the primary path.

**Trial-activation rule:** A therapist's profile is eligible to appear in search results when `therapist.locations.where(location_type: :primary).first.geocode_status == "ok"`. The current `create-account.md` plan already uses `geocode_status`; we build on it.

For the <1% write-in case, the profile stays in `geocode_status = "pending"` until the job runs. The dashboard should show a small banner ("We're finalizing your location — search listing will appear within a few minutes") until it flips to `ok`. Job runs via Solid Queue and should complete in seconds.

**Not doing:** deferring address to a post-signup page. That would create a window where the therapist appears "signed up" but has nothing searchable — confusing for the trial-period UX and against the "live right away" goal.

---

## Data Model

### New table: `therapist_targeted_zips`

```ruby
create_table :therapist_targeted_zips, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid :therapist_id, null: false
  t.string :zip, null: false, limit: 10
  t.string :city, null: false, limit: 100
  t.string :state, null: false, limit: 2
  t.decimal :latitude, precision: 10, scale: 7
  t.decimal :longitude, precision: 10, scale: 7
  t.boolean :city_match_successful, null: false, default: false
  t.string :geocode_status, null: false, default: "pending", limit: 20
  t.datetime :geocoded_at
  t.timestamps
end

add_foreign_key :therapist_targeted_zips, :therapists, on_delete: :cascade
add_index :therapist_targeted_zips, :therapist_id
add_index :therapist_targeted_zips, [:therapist_id, :zip], unique: true
```

**Cap enforcement:** `MAX_PER_THERAPIST = 5` in the controller. DB has no hard cap — trivial to raise later if needed.

### Existing `locations` table

Already has everything needed (`street_address`, `street_address2`, `city`, `state`, `zip`, `latitude`, `longitude`, `canonical_city`, `canonical_state`, `city_match_successful`, `geocode_status`, `geocoded_at`). No migration needed.

The `location_type` enum has `primary` and `alternate` (verified via Supabase MCP). We're renaming `alternate` → `additional` to match the UI copy. Only 1 row exists in `locations` and it's `primary`, so the rename is safe and has no data impact.

```ruby
# db/migrate/<ts>_rename_location_type_alternate_to_additional.rb
class RenameLocationTypeAlternateToAdditional < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TYPE location_type RENAME VALUE 'alternate' TO 'additional'"
  end

  def down
    execute "ALTER TYPE location_type RENAME VALUE 'additional' TO 'alternate'"
  end
end
```

---

## Search Performance

Napkin math at projected scale:

| Source | Max rows |
|---|---|
| Primary locations | 10,000 (one per therapist) |
| Additional locations | ~10,000 |
| Targeted ZIPs | ~50,000 (10k × 5) |
| **Total geo points** | **~70,000** |

Postgres with a btree on `(latitude, longitude)` handles radius queries on 70k rows in single-digit ms. If we need a true spatial predicate later, add a GIST index with `earth_distance` or PostGIS.

**Search-side consolidation:** not in scope for this plan, but when we wire up the client-facing search, the cleanest approach is a materialized view `therapist_search_points` that flattens all three sources into one row per geo point tagged with `therapist_id` + `source_type`. We can refresh on location/targeted-zip writes via an `after_commit` hook.

---

## Phase 1: ZIP Autocomplete (shared infrastructure)

Build the reusable combobox that the locations form, targeted ZIPs form, and `/create-account` all share.

### Files to create

| File | Purpose |
|---|---|
| `app/controllers/zip_lookups_controller.rb` | Single `GET /zip-search?q=...` endpoint. Returns JSON. |
| `app/javascript/controllers/zip_combobox_controller.js` | Stimulus controller: debounced fetch, keyboard nav (↑/↓/Enter/Esc), aria-activedescendant, blur-to-close. |
| `app/views/shared/_zip_combobox.html.erb` | Partial rendering the input + popover shell. Takes a form-name prefix so it can be reused. |

### Endpoint contract

```
GET /zip-search?q=021
→ [
    { "zip": "02138", "city": "Cambridge",    "state": "MA", "lat": 42.3799, "lng": -71.1344 },
    { "zip": "02138", "city": "Mount Auburn", "state": "MA", "lat": 42.3751, "lng": -71.1495 },
    { "zip": "02138", "city": "Old Cambridge","state": "MA", "lat": 42.3779, "lng": -71.1162 },
    ...
  ]
```

- Prefix match on `zip` only: `WHERE zip LIKE $q || '%'`.
- Dedupe on `(zip, city, state_id)`: `SELECT DISTINCT ON (zip, city, state_id)`.
- Order by `zip, city, state_id`.
- Limit 10.
- `lat` = `COALESCE(zip_lat, city_lat)`, `lng` = `COALESCE(zip_lng, city_lng)`.
- Auth: `require_auth` + `require_profile` (reuse the pattern from `about_you/colleges#search`).
- Rate-limit: 30 req/min per user (via Rack::Attack).
- Cache-Control: `private, max-age=60` — identical queries dedupe cheaply.

### Display

```
29640 — Walhalla, SC
```

- Matched digit prefix wrapped in `<mark>` (e.g. `<mark>2964</mark>0`) for visual reinforcement of what they typed.
- Icon (heroicon `map-pin`) on the left, consistent with existing combobox styling.

### Keyboard + accessibility

- `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant` on the input.
- `role="listbox"` on the popover.
- `role="option"` + `id` on each result.
- ↑/↓ moves active, Enter picks active, Esc closes, Tab closes + moves focus on.
- Mouse hover sets active (no separate hover/active states).

### Match logic on pick

When an option is clicked, the Stimulus controller fills the following fields on the surrounding form:

```
form[zip]        = "02138"
form[city]       = "Cambridge"
form[state]      = "MA"
form[latitude]   = 42.3799
form[longitude]  = -71.1344
form[city_match_successful] = "1"
```

Field names are configurable via data attributes (`data-zip-combobox-zip-field-value`, etc.) so different forms can target their own namespaced params.

---

## Phase 2: Locations Page

Replace [`app/views/your_practice/locations/show.html.erb`](app/views/your_practice/locations/show.html.erb) with an editable page showing the primary location (always) and an additional location (optional).

### Files to modify / create

| File | Change |
|---|---|
| `app/controllers/your_practice/locations_controller.rb` | Add `update`. Takes `locations[primary][...]` + `locations[additional][...]` params. On success re-renders show with flash. |
| `app/views/your_practice/locations/show.html.erb` | Two forms in one page: primary (required, can't delete) + additional (can add/remove). Both use `_zip_combobox` partial. |
| `config/routes.rb` | Change `resource :location, only: [:show]` → `only: [:show, :update]`. |

### Form structure

**Primary location card** — fields:
- Street address 1 (required)
- Street address 2 (optional)
- ZIP (with autocomplete) — required
- City, State — filled by pick but editable
- Show street address on profile (checkbox, default true)
- Save

**Additional location card** — collapsed if none exists, with "Add additional location" button.
When expanded, same fields as primary + a "Remove additional location" link.

### Write path

1. Update primary via standard `locations[primary]` params. Merge `latitude`/`longitude`/`city_match_successful` if the combobox filled them.
2. Additional location: if all fields blank + exists → destroy. If fields present → upsert (`find_or_initialize_by(therapist_id:, location_type: "additional")`).
3. After each save: if `latitude`/`longitude` came from the combobox, set `geocode_status = "ok"`, `geocoded_at = Time.current`. If write-in, try `ZipLookup.geocode_with_fallback` synchronously; if still unresolved, queue `GeocodeLocationJob` and leave status `pending`.

---

## Phase 3: Targeted ZIPs Page

### Files to create

| File | Purpose |
|---|---|
| `db/migrate/<ts>_create_therapist_targeted_zips.rb` | Migration from Data Model section. |
| `app/models/therapist_targeted_zip.rb` | `belongs_to :therapist`. Validates zip format, `validates :zip, uniqueness: { scope: :therapist_id }`. |
| `app/controllers/your_practice/targeted_zips_controller.rb` | `show`, `create`, `destroy`. |
| `app/views/your_practice/targeted_zips/show.html.erb` | List of current zips as chips + "Add targeted ZIP" form (single ZIP combobox + Save). |
| `config/routes.rb` | `resource :targeted_zips, only: [:show, :create, :destroy], path: "targeted-zips"` |

### Files to modify

| File | Change |
|---|---|
| `app/models/therapist.rb` | `has_many :therapist_targeted_zips, dependent: :destroy`. |
| `app/views/your_practice/shared/_sidebar.html.erb` | Add "Targeted ZIPs" link (position TBD — probably after "Locations"). |
| `app/views/your_practice/shared/_layout.html.erb` | Same, for mobile nav. |

### UX

- Chip list showing e.g. `29640 — Walhalla, SC ✕`.
- Each chip has a delete button (form_with, method: :delete, confirm optional).
- Below the chips: a single ZIP-autocomplete input + Add button.
- "Add" is disabled when `therapist.therapist_targeted_zips.count >= 5`.
- Server-side cap enforcement mirrors the client-side.

### Geocoding

Same pattern as locations: if the user picked from autocomplete, `latitude`/`longitude` are submitted — set `geocode_status = "ok"`. If they didn't, try `ZipLookup.geocode_with_fallback` in the controller; if that fails, queue a job (new `GeocodeTargetedZipJob` mirroring `GeocodeLocationJob`).

---

## Phase 4: Create-Account Update

Minimal — the form already collects the primary address. We just swap the ZIP field for the combobox and add synchronous geocoding.

### Files to modify

| File | Change |
|---|---|
| `app/views/create_account/new.html.erb` | Replace the plain ZIP input with the `_zip_combobox` partial. Keep city/state/zip visible and editable — the combobox just fills them. |
| `app/controllers/create_account_controller.rb` | In the `create` action, if `latitude`/`longitude` came from the combobox, set `geocode_status = "ok"` on the new location and skip the job. If write-in, run `ZipLookup.geocode_with_fallback` synchronously before saving. Only queue `GeocodeLocationJob` if the sync path fails. |

### Dashboard banner for pending geocode

If `current_therapist.primary_location.geocode_status == "pending"` on the dashboard, show:

> We're finalizing your location — your profile will appear in search results within a few minutes.

Auto-refreshes on page reload; no websocket/turbo-stream needed.

---

## Phase 5: Background Geocoding Job (minor update)

The existing [`GeocodeLocationJob`](app/jobs/geocode_location_job.rb) works for locations. Add a sibling for targeted ZIPs.

### Files to create

| File | Purpose |
|---|---|
| `app/jobs/geocode_targeted_zip_job.rb` | Mirror of `GeocodeLocationJob` against `TherapistTargetedZip`. Uses the same `ZipLookup.geocode_with_fallback`. |

---

## Open Questions

1. **Banner copy for pending geocode.** The proposed wording is fine for a placeholder; may want friendlier language before launch.
2. **Frontend-facing search integration.** Out of scope here but worth a follow-up plan — the `therapist_search_points` materialized view sketched under "Search Performance" is where I'd start.
3. **Rate limit numbers.** 30 req/min on `/zip-search` is a guess; may want to loosen for power-users typing fast.

---

## Verification

Each phase has its own verification list, but at the end of all five:

- Sign up as a brand-new user. Pick a ZIP from autocomplete. Land on dashboard with profile live (no banner).
- Sign up as a brand-new user. Type a fake ZIP (e.g. `99998`). Land on dashboard with the pending banner. Solid Queue runs the job; refresh after ~30s — banner is gone (or still shown if geocode failed).
- On `/your-practice/locations`, edit primary via autocomplete → verify `geocode_status = ok`, lat/lng populated.
- Add + remove additional location. Verify only one can exist per therapist.
- Add 5 targeted ZIPs. Try to add a 6th — blocked in UI and controller.
- Remove a targeted ZIP. Add it back. Verify unique constraint works.
- Axe/keyboard audit on the combobox: arrow keys, Enter, Esc, Tab all behave correctly with a screen reader announcing option count.

---

## File Summary

**Create:**
- `db/migrate/<ts>_rename_location_type_alternate_to_additional.rb`
- `db/migrate/<ts>_create_therapist_targeted_zips.rb`
- `app/models/therapist_targeted_zip.rb`
- `app/controllers/zip_lookups_controller.rb`
- `app/controllers/your_practice/targeted_zips_controller.rb`
- `app/javascript/controllers/zip_combobox_controller.js`
- `app/views/shared/_zip_combobox.html.erb`
- `app/views/your_practice/targeted_zips/show.html.erb`
- `app/jobs/geocode_targeted_zip_job.rb`

**Modify:**
- `app/controllers/your_practice/locations_controller.rb`
- `app/controllers/create_account_controller.rb`
- `app/models/therapist.rb`
- `app/views/your_practice/locations/show.html.erb`
- `app/views/your_practice/shared/_sidebar.html.erb`
- `app/views/your_practice/shared/_layout.html.erb`
- `app/views/create_account/new.html.erb`
- `config/routes.rb`
- `CHANGELOG.md`
