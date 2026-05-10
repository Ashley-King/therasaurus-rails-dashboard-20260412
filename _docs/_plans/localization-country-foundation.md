# Localization + Country Foundation Plan

**Date:** 2026-05-10
**Status:** Foundation implemented 2026-05-10. `locations.zip` rename is
deferred until a separate approved change.

## Goal

Prepare the backend for future translation and country support without
showing new countries or adding translated user interfaces now.

The first planned countries are:

| Country | Code | Launch status | Currency | Future locale support |
|---|---|---|---|---|
| United States | `US` | Active | `USD` | `en` |
| Canada | `CA` | Hidden | `CAD` | `en-CA`, `fr-CA` |
| Mexico | `MX` | Hidden | `MXN` | `es-MX` |

Canada and Mexico must stay hidden until they are explicitly activated.
They should not appear as "coming soon" options.

## Assumptions

- English stays the only active app language for launch.
- Canada and Mexico are backend preparation only.
- No locale switcher is added now.
- No translated routes are added now.
- No translated UI copy is added now.
- The public app remains United States only until a separate country
  launch project changes that.
- The browser must not be trusted for country access decisions.

## Current State

- Rails has only `config/locales/en.yml`.
- `config/environments/production.rb` has locale fallbacks enabled.
- Create Account loads all `Country` records and preselects `US`.
- Business rules say the app supports United States providers only.
- Locations and targeted search are built around United States ZIP codes.
- `zip_lookups` is a United States ZIP reference table.
- `locations.zip` stores ZIP codes.
- `therapist_targeted_zips` stores targeted ZIP search points.

## Standard Rails Shape

Use Rails I18n for translated text.

Use normal database columns on `countries` for country business rules.

Do not put important country rules in a JSON blob.

Do not create a custom localization framework.

The app should use:

- `config/locales/*.yml` for translated text.
- `countries` rows for country rules.
- Controllers and models for server-side enforcement.
- Views only to show what the server already allowed.

## Phase 1: Add Rails I18n Foundation

### Scope

Set up the app so new backend text has a clear place to live.

Do not translate the app yet.

### Why This Phase Comes Now

This is low risk and keeps future work from adding more hard-coded text.

### Main Changes

Create or update:

| File | Change |
|---|---|
| `config/initializers/i18n.rb` | Set `I18n.available_locales = [:en]` and `I18n.default_locale = :en`. |
| `config/locales/controllers.en.yml` | Add controller flash and error text as new work touches it. |
| `config/locales/models.en.yml` | Add model validation text as new work touches it. |
| `config/locales/mailers.en.yml` | Add Rails-owned email text as new work touches it. |
| `config/locales/views.en.yml` | Add view text only when a page is already being changed. |
| `config/locales/en.yml` | Remove the generated `hello: "Hello world"` placeholder. |

Development and test should raise on missing translations so missing keys
are visible before deploy.

### Risks Or Edge Cases

- Moving too much copy at once creates a noisy diff.
- Locale fallback can hide missing text in production.

### Validation

- Boot the app.
- Trigger common controller flashes.
- Trigger common model validation errors.
- Run RuboCop.

### Temporary Inconsistency

Some text will stay hard-coded for a while. That is acceptable. Move text
when files are already being changed.

## Phase 2: Add Country Rule Columns

### Scope

Make country support explicit in the database while keeping only the
United States active.

### Why This Phase Comes Now

Country support affects signup, location rules, billing, search, and
future translation. A small database shape now prevents scattered checks
later.

### Main Changes

Add columns to `countries`:

| Column | Purpose |
|---|---|
| `active` | Whether the country can be selected and used. |
| `default_locale` | Default locale for future localized behavior. |
| `currency_code` | Billing and display currency. |
| `postal_code_label` | User-facing label, such as `ZIP code` or `Postal code`. |
| `administrative_area_label` | User-facing label, such as `State` or `Province`. |

Seed or update:

| Code | Active | Default locale | Currency | Postal label | Area label |
|---|---|---|---|---|---|
| `US` | `true` | `en` | `USD` | `ZIP code` | `State` |
| `CA` | `false` | `en-CA` | `CAD` | `Postal code` | `Province` |
| `MX` | `false` | `es-MX` | `MXN` | `Postal code` | `State` |

Add model helpers:

- `Country.active`
- `Country.inactive`
- `Country#active?`

Do not add `supported_locales` yet. Canada can add `["en-CA", "fr-CA"]`
when Canada launch work starts.

The hidden country `default_locale` values are future values. Do not use
them to set `I18n.locale` until those locales are added to
`I18n.available_locales`.

### Likely Files

| File | Change |
|---|---|
| `db/migrate/*_add_country_rules_to_countries.rb` | Add country rule columns. |
| `app/models/country.rb` | Add scopes and validations. |
| `db/seeds.rb` or existing seed files | Ensure `US`, `CA`, and `MX` exist with correct rules. |
| `_docs/business-rules.md` | Document that only active countries are selectable. |
| `_docs/_processes/localization.md` | Document country and locale rules. |

### Risks Or Edge Cases

- Canada or Mexico could become selectable by accident.
- Existing code could load all countries instead of active countries.
- Currency could be confused with Stripe price currency.
- A validation that requires `default_locale` to be in
  `I18n.available_locales` would fail for hidden countries. Do not add
  that validation until those locales are active.

### Validation

- Confirm `US` is active.
- Confirm `CA` and `MX` are inactive.
- Confirm inactive countries cannot be used by changing request params.
- Confirm Create Account still works for the United States.
- Run RuboCop.

### Temporary Inconsistency

Canada and Mexico will exist in backend data while still hidden from the
product. This is intentional.

## Phase 3: Enforce Active Countries On The Server

### Scope

Make the United States the only accepted country until Canada or Mexico
is explicitly activated.

### Why This Phase Comes Now

Hiding a country in the browser is not enough. The server must reject
inactive countries.

### Main Changes

Update Create Account:

- Load only `Country.active.order(:name)` for the form.
- Reject a submitted country unless it is active.
- Keep `US` as the default selected country.
- Keep the current United States only help text.

### Likely Files

| File | Change |
|---|---|
| `app/controllers/create_account_controller.rb` | Load and accept active countries only. |
| `app/views/create_account/new.html.erb` | Continue showing only active countries. |
| `_docs/business-rules.md` | Clarify that inactive countries are hidden and rejected. |

### Risks Or Edge Cases

- Admin-created records might need a country. Admin paths should also use
  the same active-country rule unless a separate admin-only workflow is
  approved.
- A stale form could submit an inactive country after a country is
  deactivated.

### Validation

- Submit Create Account with `US`. It should work.
- Submit Create Account with `CA` or `MX` by changing params. It should fail.
- Submit Create Account with a missing or fake country id. It should fail.
- Run RuboCop.

### Temporary Inconsistency

No user-facing inconsistency is expected. Canada and Mexico stay hidden.

## Phase 4: Rename Targeted ZIP Backend To Postal Code

### Scope

Rename the targeted ZIP feature so the backend name works for Canada and
Mexico later.

### Decision

Rename `therapist_targeted_zips` to `therapist_targeted_postal_codes`.

Rename related model, controller, route helper, job names, params, docs,
and database columns from ZIP-specific names to postal-code names.

Keep `zip_lookups` unchanged because that table is specifically United
States ZIP data.

### Why This Phase Comes Now

The app has no users. This is the cheapest time to fix the name.

### Main Changes

Rename:

| Current | New |
|---|---|
| `therapist_targeted_zips` | `therapist_targeted_postal_codes` |
| `TherapistTargetedZip` | `TherapistTargetedPostalCode` |
| `GeocodeTargetedZipJob` | `GeocodeTargetedPostalCodeJob` |
| `targeted_zips` routes | `targeted-postal-codes` routes |
| `zip` column on targeted rows | `postal_code` |

Keep visible text as "Targeted ZIPs" while the app is United States only,
unless the same page is already being edited.

### Likely Files

| File | Change |
|---|---|
| `db/migrate/*_rename_targeted_zips_to_targeted_postal_codes.rb` | Rename table and column. |
| `app/models/therapist.rb` | Rename association. |
| `app/models/therapist_targeted_zip.rb` | Rename model file and class. |
| `app/controllers/your_practice/targeted_zips_controller.rb` | Rename controller and params. |
| `app/jobs/geocode_targeted_zip_job.rb` | Rename job. |
| `app/views/your_practice/targeted_zips/index.html.erb` | Rename paths and params as needed. |
| `config/routes.rb` | Rename route path and helper. |
| `_docs/_processes/locations.md` | Update current behavior docs. |
| `_docs/business-rules.md` | Update targeted postal code rules. |

### Risks Or Edge Cases

- Route helper changes can break sidebar links.
- Job class rename can break queued jobs if deployed while old jobs still
  exist.
- Search or geocoding code can still expect `zip`.

Because the app has no users and has not been deployed, no legacy job
compatibility is needed.

### Validation

- Add a targeted ZIP.
- Remove a targeted ZIP.
- Try to add a duplicate.
- Try to add a sixth targeted ZIP.
- Confirm geocoding still runs for unresolved United States ZIPs.
- Run RuboCop.

### Temporary Inconsistency

Some user-facing copy may still say ZIP while backend names say postal
code. That is acceptable while the app is United States only.

## Phase 5: Add Country-Aware Postal Code Rules

### Scope

Move hard-coded ZIP validation into one simple country-aware place.

Keep only the United States active.

### Why This Phase Comes Now

Canada and Mexico use postal codes. The app should stop treating United
States ZIP rules as global rules.

### Main Changes

Add one small country postal code rule object or model method.

Rules for now:

| Country | Active | Postal code rule |
|---|---|---|
| `US` | Yes | Exactly 5 digits. |
| `CA` | No | Planned. Do not accept yet. |
| `MX` | No | Planned. Do not accept yet. |

Do not add Canada or Mexico postal lookup data yet.

Do not make `zip_lookups` handle Canada or Mexico.

### Likely Files

| File | Change |
|---|---|
| `app/models/country.rb` | Add postal code validation helpers if simple enough. |
| `app/controllers/create_account_controller.rb` | Use country-aware postal validation. |
| `app/models/location.rb` | Use country-aware postal validation if the model has access to country through therapist. |
| `app/models/therapist_targeted_postal_code.rb` | Use country-aware postal validation when the rename is done. |
| `app/models/concerns/geocodable.rb` | Keep United States ZIP lookup scoped to United States behavior. |

### Risks Or Edge Cases

- `Location` belongs to `Therapist`, not directly to `Country`.
- Country-aware validation must not make model code hard to trace.
- Mexico uses 5 digits, but the United States `zip_lookups` table must not
  be used for Mexico.

### Validation

- United States 5 digit ZIPs still pass.
- Bad United States ZIPs still fail.
- Canada and Mexico still cannot be selected or submitted.
- Run RuboCop.

### Temporary Inconsistency

Some database columns may still be named `zip` on `locations` until a
separate location-column rename is approved.

## Phase 6: Decide Whether To Rename `locations.zip`

### Scope

Decide whether to rename `locations.zip` to `locations.postal_code`.

### Recommendation

Rename it before Canada work starts.

Do not do it in the same change as the targeted postal code rename unless
the targeted rename is already small and clean.

### Why This Phase Comes Later

`locations.zip` is central to account creation, location editing,
geocoding, and search eligibility. It has a larger risk than the targeted
postal code table rename.

### Main Changes

If approved later:

| Current | New |
|---|---|
| `locations.zip` | `locations.postal_code` |
| `Location#zip` | `Location#postal_code` |
| location params `zip` | location params `postal_code` |

Keep `zip_lookups.zip` as-is.

### Risks Or Edge Cases

- Create Account may fail if params are missed.
- Location editing may fail if form field names are missed.
- Geocoding jobs may fail if they still read `zip`.
- Docs and Avo resources may drift.

### Validation

- Create Account with a United States ZIP.
- Edit primary location.
- Add and remove additional location.
- Confirm geocoding still works.
- Run RuboCop.

### Temporary Inconsistency

If this phase is delayed, the app will have targeted postal codes but
locations still store `zip`. That is acceptable for a short period.

## Phase 7: Move Backend Text As Files Are Touched

### Scope

Move backend-generated English text into locale files during normal work.

Do not start a full translation pass.

### Why This Phase Comes Later

Moving every string now is busywork. The better use of time is to move
text when the related code is already being changed.

### Main Changes

Move these first:

- Controller flash messages.
- Model validation messages.
- Mailer subjects.
- Rails-owned email copy.

Defer these:

- Full page copy.
- Navigation copy.
- Marketing copy.
- Supabase auth emails.
- Stripe hosted emails.
- Stripe Customer Portal text.

### Risks Or Edge Cases

- Keys can become hard to find if names are too generic.
- Missing interpolation values can break messages.

### Validation

- Trigger each moved flash.
- Trigger each moved validation.
- Preview or send each moved Rails email.
- Run RuboCop.

### Temporary Inconsistency

Some backend text will use locale files and some text will remain inline.
That is acceptable until a future translation project starts.

## Phase 8: Documentation

### Scope

Keep country and localization rules easy to find.

### Main Changes

Create or update:

| File | Change |
|---|---|
| `_docs/_processes/localization.md` | Document active locales, hidden countries, and country rules. |
| `_docs/index.md` | Link to the localization process doc. |
| `_docs/business-rules.md` | Update United States-only and inactive-country rules. |
| `_docs/_processes/locations.md` | Document that `zip_lookups` is United States only. |
| `CHANGELOG.md` | Add entries when this work is implemented. |

### Risks Or Edge Cases

- Docs can imply Canada or Mexico are ready if the wording is loose.

### Validation

- Confirm docs say Canada and Mexico are hidden.
- Confirm docs say Canada and Mexico are not coming soon.
- Confirm docs say only the United States is active.

### Temporary Inconsistency

None expected.

## Risks

- Canada or Mexico could become visible before search, billing, tax,
  credential, and location rules support them.
- Future code could treat translation and country launch as the same work.
  They are related, but they are not the same.
- Keeping `zip` names in backend code too long will make Canada support
  harder.
- Adding too much localization setup now could slow down launch without
  creating real value.

## Open Questions

- Should `locations.zip` be renamed in the first implementation pass, or
  should it wait until the targeted postal code rename is finished?
- Should Canada use `en-CA` as the default locale, or should the default
  depend on the therapist's chosen language when Canada launches?
- Should country launch later require separate Stripe prices per country,
  or should Stripe Tax and one currency stay in place until revenue proves
  the need?
