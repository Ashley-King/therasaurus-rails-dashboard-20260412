# Create Account + Geocoding Plan

**Date:** 2026-04-13
**Status:** Approved

## Overview

Add the create-account step between OTP verification and the dashboard. A logged-in user who hasn't finished their profile is redirected to `/create-account`. After submission, a background job geocodes their primary location using the `zip_lookups` table.

---

## Profile Completion Detection

A user has completed their profile if `current_user.therapist.present?`. No separate `profile_completed` boolean needed — the therapist record IS the proof of account creation.

---

## Routing & Access Control

| Route | Normal user (no profile) | Normal user (has profile) | Admin (no profile) | Admin (has profile) |
|---|---|---|---|---|
| `/signin`, `/verify` | Allowed | Redirect to dashboard | Allowed | **Allowed** (no redirect) |
| `/create-account` | **Allowed** | Redirect to dashboard | **Allowed** | **Allowed** (can view) |
| `/dashboard` + all dashboard routes | Redirect to create-account | Allowed | Redirect to create-account | Allowed |

---

## Phase 1: Access Control & Redirects

Update the auth concern and controllers so that unauthenticated and profileless users are routed correctly before the form even exists.

### Files to modify

| File | Change |
|---|---|
| `app/controllers/concerns/authentication.rb` | Add `require_profile` before_action (redirects to `/create-account` if `current_therapist.blank?`). Add `profile_complete?` helper method. |
| `app/controllers/auth_controller.rb` | Update `redirect_if_signed_in`: non-admin users with a profile redirect to dashboard; admin users are never redirected. Update `confirm` action: after OTP, redirect to `/create-account` if no therapist, otherwise `/dashboard`. |
| `app/controllers/dashboard_controller.rb` | Add `before_action :require_profile` |
| `app/controllers/about_you/base_controller.rb` | Add `before_action :require_profile` |
| `app/controllers/your_practice/base_controller.rb` | Add `before_action :require_profile` |
| `app/controllers/account_settings/base_controller.rb` | Add `before_action :require_profile` |
| `config/routes.rb` | Add `get "create-account"` and `post "create-account"` routes |

### Verification

- A logged-in user without a therapist record hitting `/dashboard` is redirected to `/create-account`.
- A logged-in user with a therapist record hitting `/create-account` is redirected to `/dashboard`.
- An admin user can access `/signin`, `/verify`, and `/create-account` regardless of profile state.
- OTP confirmation sends profileless users to `/create-account` instead of `/dashboard`.

---

## Phase 2: Create Account Form & Controller

Build the form page and controller that creates the therapist + primary location records.

### Files to create

| File | Purpose |
|---|---|
| `app/controllers/create_account_controller.rb` | Controller with `new` and `create` actions, uses `auth` layout. `before_action :require_auth`. `before_action :redirect_if_profile_complete` (non-admin with profile -> dashboard). `new` loads professions, countries, states. `create` validates, saves in transaction, redirects to dashboard. |
| `app/views/create_account/new.html.erb` | Form matching the Next.js create-account layout (wide card, two sections). |

### Files to modify

| File | Change |
|---|---|
| `app/assets/tailwind/application.css` | Add `.ts-auth-card-wide` variant (max-width: 48rem) for the wider create-account card. |

### Form Fields

Matches the existing Next.js create-account form exactly.

**Read-only:**
- Email (from `current_user.email`)

**Personal Information section:**
- First Name (required, max 50, placeholder "Lucy", autocomplete given-name)
- Last Name (required, max 50, placeholder "Miller", autocomplete family-name)
- Credentials (optional, max 50, placeholder "PhD, OTR/L")
- Profession (required, select dropdown from `professions` table, help text: "Don't see your profession? Email support@therasaurus.org")

**Primary Business Location section:**
- Street Address (required, max 120, autocomplete street-address)
- Suite/Unit/Floor (optional, max 120, autocomplete address-line2)
- City (required, max 50, autocomplete address-level2)
- State (required, select dropdown from `states` table, 2-letter code)
- ZIP Code (required, 5 digits, maxlength 5, autocomplete postal-code)
- Show street address on profile (checkbox, default true)
- Country (required, select from `countries` table, default US, help text about US-only support)

**Submit button:** "Create Account"

### Form Submission Logic

1. Validate required fields server-side (first_name, last_name, profession_id, country_id, street_address, city, state, zip)
2. Validate state is a 2-letter code, zip is 5 digits, profession/country exist in DB
3. In a transaction: create `Therapist` (with generated `profile_slug`) and `Location` (type: primary)
4. Generate `profile_slug` from `first_name-last_name-profession_slug` (matching the Next.js RPC logic)
5. On success: redirect to `/dashboard`
6. On validation failure: re-render form with errors

### Verification

- Form renders with all fields populated from reference data.
- Submitting valid data creates a therapist + location and redirects to dashboard.
- Submitting invalid data re-renders the form with field-level errors.
- Profile slug is generated correctly.

---

## Phase 3: Geocoding Background Job

> **Superseded (2026-04-21).** The explicit `GeocodeLocationJob.perform_later` call in `CreateAccountController#create` has been removed. Geocoding now happens on the `Location` model itself via the `Geocodable` concern: a `before_save` runs `ZipLookup.geocode_with_fallback` synchronously (trusting lat/lng the ZIP combobox already filled), and an `after_commit` enqueues `GeocodeLocationJob` **only** when the sync path couldn't resolve. See [`_processes/locations.md`](../_processes/locations.md) for the current flow.

Add the background job that resolves lat/lng from the `zip_lookups` table after account creation.

### Files to create

| File | Purpose |
|---|---|
| `app/jobs/geocode_location_job.rb` | Solid Queue job with three-stage fallback geocoding logic. |
| `app/models/zip_lookup.rb` | Read-only model for `zip_lookups` table (`self.table_name = "zip_lookups"`). |

### Files to modify

| File | Change |
|---|---|
| `app/controllers/create_account_controller.rb` | Add `GeocodeLocationJob.perform_later(location.id)` after successful save in `create` action. |

### Trigger

Enqueued at the end of `CreateAccountController#create` after the therapist + location are saved:

```ruby
GeocodeLocationJob.perform_later(location.id)
```

### Three-Stage Fallback Logic

Queries the `zip_lookups` table (indexed on `zip`, `zip + state_id`, and `city` via trigram).

| Stage | Query | `city_match_successful` |
|---|---|---|
| 1. Perfect match | `WHERE zip = ? AND state_id = ? AND (lower(city) = ? OR lower(city_alt) = ?)` | `true` |
| 2. State+ZIP fallback | `WHERE zip = ? AND state_id = ?` (first result) | `false` |
| 3. ZIP-only fallback | `WHERE zip = ?` (first result) | `false` |

### On Match

Updates the location record with:

- `latitude` -> `city_lat` from zip_lookups (preferred), fall back to `zip_lat`
- `longitude` -> `city_lng` from zip_lookups (preferred), fall back to `zip_lng`
- `canonical_city` -> `city` from the matched zip_lookups row
- `canonical_state` -> `state_id` from the matched zip_lookups row
- `city_match_successful` -> `true` only if Stage 1 matched
- `geocoded_at` -> `Time.current`
- `geocode_status` -> `"ok"`

### On No Match (all 3 stages fail)

- `geocode_status` -> `"failed"`
- `geocoded_at` -> `Time.current`
- lat/lng stay nil

### Input Normalization (before querying)

- ZIP: first 5 digits only
- State: uppercase, 2-letter code
- City: stripped, downcased for comparison

### Idempotency

The job is safe to run multiple times. It overwrites the geocode fields with the latest result.

### Verification

- Creating an account with a valid city/state/zip sets lat/lng and `geocode_status = "ok"` on the location.
- A perfect city match sets `city_match_successful = true` and populates `canonical_city`/`canonical_state`.
- A city mismatch (wrong city for that zip) falls back to Stage 2, sets `city_match_successful = false`, and still populates lat/lng.
- A bad state falls back to Stage 3 (zip-only).
- A completely invalid zip sets `geocode_status = "failed"` with nil lat/lng.

---

## What This Plan Does NOT Include (by design)

- No phone/ext/show_phone fields (managed in dashboard profile editing, not in create-account)
- No membership/trial logic (separate step)
- No welcome email or activation nudges (can add later)
- No Supabase `app_metadata` sync (Rails uses `current_user.therapist.present?` instead)
- No address hashing / stale-write protection (Solid Queue runs fast enough against local DB)
- No separate geocoding_failures table (`geocode_status = "failed"` on location is sufficient)
- No webhook/notification on city mismatch (check `city_match_successful = false` in dashboard later)
- No caching for zip_lookups queries (indexed DB queries are fast enough)
