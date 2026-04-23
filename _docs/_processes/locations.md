# Locations + Targeted ZIPs + Geocoding

How primary/additional locations and targeted ZIPs are captured, geocoded, and kept searchable.

## Tables

| Table | Purpose |
|---|---|
| `locations` | One `primary` + optionally one `additional` row per therapist. Full street address + geocode state. |
| `therapist_targeted_zips` | Up to 5 `(zip, city, state)` tuples a therapist wants to appear in search results for, with no physical office. |
| `zip_lookups` | Read-only reference table (~131k rows, 39k unique ZIPs) backing the ZIP autocomplete + fallback geocoder. |

The `location_type` Postgres enum is `("primary", "additional")` (renamed from `alternate` in migration `20260421000000`). The `locations` table uniqueness of primary is enforced by app logic (`find_or_initialize_by(location_type: "primary")`), not a DB constraint.

## Geocodable concern

`app/models/concerns/geocodable.rb` is included by both `Location` and `TherapistTargetedZip`. It wires up two callbacks:

### `before_save :resolve_geocode`
Guarded by `address_changed_or_unresolved?` so unrelated edits (e.g. toggling `show_street_address`) don't re-geocode.

Logic:

1. **Trust combobox-filled coords.** If `latitude` and `longitude` are already set on the record (because the ZIP combobox picked a suggestion), set `geocode_status = "ok"` / `geocoded_at = Time.current` and return.
2. **Sync fallback via `ZipLookup.geocode_with_fallback`** (three stages: zip+state+city → zip+state → zip). If a row matches, copy `lat/lng`, `city_match_successful`, and (on `Location` only, guarded by `has_attribute?`) `canonical_city` / `canonical_state`. Mark `ok`.
3. **Mark pending.** If nothing matched, leave `geocode_status = "pending"`.

### `after_commit :enqueue_geocode_if_pending`
If status landed on `"pending"`, enqueue `#geocode_job_class.perform_later(id)`. Each model implements the hook:
- `Location#geocode_job_class` → `GeocodeLocationJob`
- `TherapistTargetedZip#geocode_job_class` → `GeocodeTargetedZipJob`

The jobs do the same three-stage match and write `ok` or `failed`.

### Why this shape

- **Combobox pick = zero jobs** (the ~95% case). Lat/lng land in the request cycle, signup/edit is "live" immediately.
- **Manual write-in that matches `zip_lookups` = zero jobs** (the ~4% case). Sync fallback resolves inline.
- **Only unresolved ZIPs** (the <1% case — a valid 5-digit ZIP not yet in `zip_lookups`) flip to `pending` and get a background retry.

## ZIP combobox (`_zip_combobox` partial + `zip-combobox` Stimulus controller)

Single partial drives the ZIP field across `/create-account`, `/your-practice/locations`, and `/your-practice/targeted-zips`. Three UI states:

| State | Visible | Form submits |
|---|---|---|
| `empty` | ZIP finder input + "Can't find your ZIP?" checkbox | Blocks empty submit (native `required`); blocks "typed but not committed" submit via JS guard. |
| `selected` | Chip: `02138 — Cambridge, MA ×` | ZIP, city, state from the pick + hidden `latitude`, `longitude`, `city_match_successful=1`. |
| `manual` | Plain City → State → ZIP inputs (stacked, all required) | Same keys but `latitude`/`longitude` empty and `city_match_successful=0`, so the server falls through to `geocode_with_fallback`. |

**Implementation notes:**
- Two inputs share `name="<prefix>[zip]"`, one in the finder and one in the manual section. The Stimulus controller toggles `disabled` so only the mode-appropriate one submits.
- `city` / `state` inputs live inside the manual section but stay enabled in all modes so autocomplete-picked values survive into `selected`. The controller toggles `required` on them only while the manual section is visible (browsers don't gracefully validate hidden-but-required fields).
- `ZipLookup.prefix_search` returns `city_alt` rows as separate options, so therapists searching under the common name (`Ventura` for `San Buenaventura`, `Saint Lucie` for `Port Saint Lucie`) find their ZIP.

## `/zip-search` endpoint

- `GET /zip-search?q=021` → JSON array of `{zip, city, state, lat, lng}`.
- Auth gate: `require_auth` (no `require_profile`, so `/create-account` can use it pre-onboarding).
- Query must be 2–5 digits (`\A\d{2,5}\z`); anything else returns `[]`.
- Rate limit: 30 req/min per IP via Rack::Attack (`zip-search/ip`).
- Response is `Cache-Control: private, max-age=60` so identical prefixes dedupe cheaply.

## Pages

| Route | Controller | What it does |
|---|---|---|
| `GET /create-account` | `CreateAccountController#new` | Captures primary location via the combobox under `params[:location]`. |
| `POST /create-account` | `CreateAccountController#create` | Builds therapist + primary `Location`; passes `latitude`/`longitude`/`city_match_successful` through so `Geocodable#resolve_geocode` trusts them. |
| `GET /your-practice/locations` | `YourPractice::LocationsController#show` | Two cards: primary (always, required) + additional (optional, collapsible). |
| `PATCH /your-practice/locations` | `YourPractice::LocationsController#update` | Reads `locations[primary][...]` OR `locations[additional][...]`. A submit button named `locations[additional][remove]=1` destroys the additional. |
| `GET /your-practice/targeted-zips` | `YourPractice::TargetedZipsController#index` | Chip list of saved ZIPs + add-form (cap: 5). |
| `POST /your-practice/targeted-zips` | `TargetedZipsController#create` | Adds one ZIP; `within_therapist_cap` validation blocks the 6th. Unique index on `(therapist_id, zip)`. |
| `DELETE /your-practice/targeted-zips/:id` | `TargetedZipsController#destroy` | Removes a single chip. |

## Pending-geocode banner

`app/views/layouts/dashboard.html.erb` renders a blue info banner when `current_therapist&.primary_location&.geocode_status == "pending"`:

> Finalizing your location — Your profile will appear in search results within a few minutes.

It disappears on the next page load once the job flips status to `ok` (or `failed`, in which case the banner also hides — we don't yet surface a separate error state to the user).

## Search eligibility

A therapist's profile is eligible to appear in directory search results when `therapist.primary_location.geocode_status == "ok"` and lat/lng are non-null. See also [`business-rules.md`](../business-rules.md).

## Verification matrix

| Scenario | Expected |
|---|---|
| Create account via combobox pick | `geocode_status = "ok"`, no job queued, no banner. |
| Create account with write-in ZIP that's in `zip_lookups` | `geocode_status = "ok"` via sync fallback, no job queued, no banner. |
| Create account with unresolved ZIP (e.g. `99998`) | `geocode_status = "pending"`, `GeocodeLocationJob` queued, banner shows. |
| Toggle `show_street_address` only | No re-geocode (callback guard skips it). |
| Add 6th targeted ZIP | Validation error "You can save at most 5 targeted ZIPs". |
| Add duplicate targeted ZIP | Validation error "Zip already added for this therapist"; DB unique index backs it up. |
