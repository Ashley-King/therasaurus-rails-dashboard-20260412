# Changelog

## 2026-04-23

### Changed
- **Clients & Availability split into two sections.** The single
  `/your-practice/clients-availability` show page (display-only with
  dead "Edit" links) is replaced by two edit pages with forms, matching
  the one-page-one-form pattern used elsewhere in `Your Practice`.
  - `/your-practice/clients` — `accepting_new_clients`, `has_waitlist`
    (mutually exclusive, preserved from the existing model validation),
    `free_phone_call`, plus age-group / language / faith checkbox
    multi-selects.
  - `/your-practice/availability` — in-person / virtual toggles,
    session-format checkboxes, extended availability (early morning,
    evening, weekend), availability notes, and telehealth platforms.
    The telehealth section only reveals when "Virtual therapy" is
    checked (via the new `toggle-visibility` Stimulus controller).
  Sidebar and mobile nav now show "Clients" and "Availability" as
  separate entries.

- **Telehealth platforms are now a many-to-many.** Replaces the unused
  `therapists.telehealth_platform` string column with a
  `telehealth_platforms` table + `practice_telehealth_platforms` join,
  seeded with the six common pediatric-therapy platforms (Zoom for
  Healthcare, Doxy.me, SimplePractice, TheraPlatform, Google Meet,
  Presence). A new `telehealth_platform_other` string on `therapists`
  captures freeform additions (comma-separated). Admin-curated via a
  new Avo resource. Migration: `20260423221610_create_telehealth_platforms`.

- **Session format: added "Parent-child".** Pediatric-relevant fourth
  option alongside Individual / Group / Family, seeded directly into
  `session_formats`.

- **Introduction: 1,500-character cap.** `Therapist` now validates
  `practice_description` against `PRACTICE_DESCRIPTION_MAX = 1500`,
  measuring visible text length (HTML tags stripped via
  `ActionView::Base.full_sanitizer`) so tag overhead doesn't eat into
  the user's budget. The Trix editor shows a live `count / 1500`
  counter (red once over the cap), and the form displays the
  per-field validation error inline if a submission slips past the
  client-side count.

- **Your Practice → Introduction is now a rich-text editor.** The
  read-only preview + "Edit" / "Add" toggle on
  `/your-practice/introduction` is replaced with an always-visible
  Trix editor that writes to `therapists.practice_description`
  (column is `character varying` with no length limit, effectively
  `text` in Postgres — no migration required). A custom
  `<trix-toolbar>` exposes only bold, bulleted list, numbered list,
  undo, and redo — no headings, italic, underline, links, quotes,
  attach. The `rich-text-editor` Stimulus controller imports Trix,
  blocks `trix-file-accept` (ActiveStorage is not installed), and
  bubbles `trix-change` as an `input` event so `form-guard` still
  catches unsaved changes. `IntroductionsController#update`
  sanitizes the submitted HTML to `%w[div br strong ul ol li]` before
  save so anything pasted in (links, headings, scripts) is stripped
  at the boundary. Trix JS + CSS are vendored under
  `vendor/javascript/trix.js` and
  `vendor/assets/stylesheets/trix.css`; pinned via importmap; the
  stylesheet is loaded from the `dashboard` layout.

## 2026-04-21

### Changed
- **Create-account form uses the ZIP combobox (phase 4 of the locations
  + targeted ZIPs plan).** The standalone City / State-select / ZIP
  trio on `/create-account` is replaced with the shared
  `_zip_combobox` partial under `params[:location]`. Picking a
  suggestion fills lat/lng and the `Location` model trusts them
  (sync `geocode_status = "ok"`, no background job). Manual entry
  still falls through `ZipLookup.geocode_with_fallback` on save; only
  an unresolved ZIP flips the record to `pending` and enqueues
  `GeocodeLocationJob` via the `Geocodable` `after_commit`. The
  dashboard layout now shows a blue info banner — "Finalizing your
  location / Your profile will appear in search results within a few
  minutes" — whenever `current_therapist.primary_location.geocode_status
  == "pending"`, so the <1% of signups that land in pending state
  know why they aren't searchable yet.

- **ZIP combobox: three-state UX (empty / selected / manual).** The
  partial now shows just the ZIP finder and a "Can't find your ZIP?
  Enter it manually." checkbox on first render. Picking a suggestion
  replaces the finder with a chip (`02138 — Cambridge, MA ×`) and
  hides the checkbox. Checking the box **replaces the finder entirely**
  with a stacked `City → State → ZIP` trio (all required; state is a
  `<select>`) — autocomplete is off, lat/lng
  are cleared, and the server falls back to
  `ZipLookup.geocode_with_fallback`. State is a `<select>` populated
  from `us_state_codes` (new `ApplicationHelper` memo), city placeholder
  is "San Francisco". The form always submits exactly one `[zip]` value:
  the partial renders two inputs with the same name (one in the finder,
  one in the manual section) and the Stimulus controller toggles
  `disabled` on them so only the mode-appropriate one is part of the
  form. City/state are toggled `required` only while the manual section
  is actually visible (browsers don't gracefully validate
  hidden-but-required fields). A submit-time guard blocks the "typed a
  ZIP but didn't pick and didn't enable manual" case with an inline hint.

### Added
- **Your Practice → Targeted ZIPs: new page (phase 3 of the locations
  + targeted ZIPs plan).** Therapists can save up to 5 `(zip, city,
  state)` tuples they want to appear in search results for, even
  without a physical office there. New table
  `therapist_targeted_zips` (migration
  `20260421000001_create_therapist_targeted_zips`), new model
  `TherapistTargetedZip` with a `within_therapist_cap` validation
  enforcing `MAX_PER_THERAPIST = 5` and a unique index on
  `(therapist_id, zip)`. New controller
  `YourPractice::TargetedZipsController` with `index`, `create`, and
  `destroy`. New sibling job `GeocodeTargetedZipJob` mirrors
  `GeocodeLocationJob` as the async fallback. The `before_save` +
  `after_commit` geocoding pattern is extracted from `Location` into
  a new `Geocodable` concern that both models include — `Location`
  keeps setting `canonical_city`/`canonical_state` (guarded by
  `has_attribute?`) while `TherapistTargetedZip` doesn't have those
  columns. Sidebar + mobile nav both show the new "Targeted ZIPs"
  entry directly below "Locations". Route: `/your-practice/targeted-zips`.

- **Your Practice → Locations: editable primary + additional (phase 2
  of the locations + targeted ZIPs plan).** The read-only placeholder
  is replaced with two cards:
  - **Primary location** (always present, required): street address,
    optional line 2, ZIP autocomplete combobox (fills city/state/lat/lng
    on pick), and "show street address on profile" checkbox.
  - **Additional location** (optional, up to 1): same fields, hidden
    behind an "Add additional location" button when none exists; has
    its own Save and a "Remove additional location" submit that
    destroys the record via a `_destroy=1` flag with `formnovalidate`.
  Saves hit `PATCH /your-practice/locations`. `LocationsController#update`
  reads `locations[primary][...]` or `locations[additional][...]` and
  delegates geocoding to a `before_save` callback on `Location` — if
  lat/lng came from the combobox they're trusted; otherwise
  `ZipLookup.geocode_with_fallback` runs inline. Only when the sync
  path returns nothing does the model set `geocode_status = "pending"`
  and its `after_commit` callback enqueues `GeocodeLocationJob`. The
  redundant `GeocodeLocationJob.perform_later` call in
  `CreateAccountController#create` is removed — the model callback
  covers it now.
  Also renames the `location_type` enum value `alternate` → `additional`
  to match the UI copy (migration
  `20260421000000_rename_location_type_alternate_to_additional`; one
  existing row is `primary`, so the rename has no data impact). New
  Stimulus controller `additional-location` handles the Add toggle.

- **ZIP autocomplete shared infrastructure (phase 1 of the locations +
  targeted ZIPs plan).** New `GET /zip-search` JSON endpoint
  (`ZipLookupsController#search`) returns up to 10 `(zip, city, state,
  lat, lng)` suggestions from `zip_lookups`, deduped on
  `(zip, city, state_id)` and limited to 5-digit numeric prefixes ≥ 2
  chars. Results include `city_alt` values as separate options so
  therapists searching under a common name (e.g. `Ventura` for
  `San Buenaventura`, `Saint Lucie` for `Port Saint Lucie`) can
  still find their ZIP. Query logic lives on
  `ZipLookup.prefix_search`. Requires auth (no `require_profile`, so `/create-account` can
  use it). Rate-limited at 30 req/min per IP via Rack::Attack. New
  `zip-combobox` Stimulus controller and
  `app/views/shared/_zip_combobox.html.erb` partial render the ZIP +
  City + State inputs plus hidden `latitude`/`longitude`/
  `city_match_successful` fields — picking a suggestion fills all six
  so the form can skip background geocoding. Editing the ZIP after a
  pick clears the hidden fields so the server falls back to
  `ZipLookup.geocode_with_fallback`. Not yet wired into any page; that
  happens in phases 2–4.

- **Your Practice: three new pages.** "Practice Details" is renamed to
  "Practice Information" and narrowed to its own page (practice name +
  "use practice name" toggle, website, required phone + optional
  extension, "show phone on profile" toggle). Accessibility and Social
  Media are promoted to their own pages with their own forms —
  Accessibility is now a 3-column alphabetized checkbox list of
  `accessibility_options`; Social Media is nine platform URL fields
  persisted to `therapists.social_media` jsonb. Routes:
  `/your-practice/practice-information`, `/your-practice/accessibility`,
  `/your-practice/social-media`.

### Changed
- **Your Practice sidebar order.** New order: Practice Information →
  Locations → Introduction → Clients & Availability → Accessibility →
  Fees & Payments → Services & Specialties → Social Media → FAQs.

## 2026-04-20

### Added
- **About You → Professional development: editable additional-training
  form.** Replaces the read-only placeholder. Therapists can enter up to
  three trainings, each with an optional year and a description (e.g.
  `C/NDT Certification`). Follows the same "hidden slot + add button"
  pattern as Education. New column `therapist_continuing_education.year`
  (nullable integer), migration
  `20260420000000_add_year_to_therapist_continuing_education`.

### Changed
- **Account settings: email change flow rebuilt.** The
  `/account-settings/update-email` page now lets users actually change
  their email instead of showing a "contact support" notice. Submitting
  a new address calls Supabase `PUT /auth/v1/user` (via
  `SupabaseAuth#request_email_change`) to send an 8-digit code to the
  new address. The page then swaps to an OTP input; verifying calls
  `POST /auth/v1/verify` with `type: "email_change"` and updates
  `users.email` in Rails. Pending changes persist in the session so
  users can leave and come back, and a "Use a different email" button
  discards state. Rate-limited at the controller layer.

## 2026-04-19

### Added
- `R2OrphanCleanupJob` (daily at 04:00 via `config/recurring.yml` +
  Avo action on the UserCredential resource) deletes R2 objects with no
  DB reference. Covers both the public `R2_HEADSHOTS_BUCKET_NAME` bucket
  (profile photos, prefix `profiles/`) and the private `ptd-credentials`
  bucket (credential docs, prefix `credentials/`). Safety rules: 24h age
  gate (no fresh uploads get touched), prefix-scoped listing, every
  deleted key logged at INFO. Docs at
  [`_docs/_background-jobs/r2_orphan_cleanup_job.md`](_docs/_background-jobs/r2_orphan_cleanup_job.md).

### Changed
- **Profile photo storage unified to the same key-only pattern as
  credentials.** `therapists.practice_image_url` column renamed to
  `practice_image_key`; the column now stores the R2 object key
  (e.g. `profiles/<uuid>/<timestamp>-<hash>.jpg`). Full URL is computed
  on demand in `Therapist#practice_image_url` from `R2_PUBLIC_URL` + key.
  Matches what Rails Active Storage / Shrine / Carrierwave do: provider
  independence, CDN flexibility, env safety, easier orphan cleanup. The
  `presigned_uploads_controller` now returns `{ presigned_url, key }`
  (no `public_url`); the JS controller saves the key; the account update
  endpoint responds with the computed URL for the UI to display.
  Pre-launch wipe of the column authorized by project owner.

### Security
- **Credential documents now upload to the private `ptd-credentials`
  R2 bucket** instead of the public `R2_HEADSHOTS_BUCKET_NAME` bucket.
  Previously `AboutYou::CredentialUploadsController` was writing state
  license / supervisor ID PDFs into the public profile-photo bucket and
  storing a permanent public URL in the DB, meaning any therapist's
  license document was readable by anyone who could guess the path.
  Upload now returns the R2 object key (not a URL); `credential_document`
  stores only that key. Admin-only download endpoint
  (`GET /admin-tools/credentials/:id/document`, routed to
  `AdminTools::CredentialDocumentsController#show`) mints a 5-minute
  presigned GET URL on demand and redirects. New R2 credential:
  `R2_CREDENTIALS_BUCKET_NAME`.
- Avo `UserCredential` resource has a new "Download" link that uses the
  same admin-only endpoint.

### Changed
- Enforced one-credential-per-therapist:
  - `Therapist has_many :user_credentials` → `has_one :user_credential`.
  - Added `validates :therapist_id, uniqueness: true` on `UserCredential`.
  - New unique index on `user_credentials.therapist_id` (DB-level guard
    against races).
  - Avo Therapist resource: `:has_many` → `:has_one`.
- Switching credential types (e.g. state_license → organization) now
  resets `credential_document`, `credential_document_original_name`,
  `credential_status` (→ `pending_review`), `verified_at`, and
  `pending_since`, on top of the existing blanking of the other type's
  fields. A type switch is effectively a new credential for verification.

### Changed
- All editable forms now stack fields vertically — one field per row.
  Removed `grid-cols-2` side-by-side layouts from primary credentials
  (state / license / expiration / org name / member ID / credential
  level), education (degree / graduation year), and account settings
  (first name / last name). Narrow fields keep `sm:w-1/2` (or `sm:w-32`
  for 4-digit year inputs) so they don't stretch the whole card.

### Changed
- Primary credential expiration dates are now month-precision only.
  Two plain text inputs (`MM` + `YYYY`, both using the `digits-only`
  Stimulus controller) replace the full-date picker on state-license,
  organization, and supervised credential types. The controller combines
  the two fields into the last day of the selected month and writes the
  existing `date` column (`license_expiration_date` /
  `organization_expiration_date`). Native `<input type="month">` was
  tried first but looked terrible.
- `UserCredential` has a new `GRACE_PERIOD` constant (2 weeks) and a
  `before_save` that computes `grace_expires_at = expiration_date.end_of_day
  + GRACE_PERIOD` from whichever column applies to the credential's type.

### Added
- `CredentialGraceExpirationJob` (in `app/jobs/`) scheduled daily at 03:00
  via `config/recurring.yml` (`expire_credentials_past_grace`). Flips any
  `PENDING_REVIEW` / `VERIFIED` credential past `grace_expires_at` to
  `EXPIRED`. Idempotent. Docs at
  [`_docs/_background-jobs/credential_grace_expiration_job.md`](_docs/_background-jobs/credential_grace_expiration_job.md)
  and [`_docs/_cron-jobs/expire_credentials_past_grace.md`](_docs/_cron-jobs/expire_credentials_past_grace.md).

### Removed
- `user_credentials.last_verified_expires_at` column (was an unused orphan).
  Migration also wipes the `user_credentials` table — pre-launch clean
  slate authorized by the project owner; no real users yet.

## 2026-04-17

### Changed
- Every text link now underlines on hover (in addition to the existing
  color change). Covers the Edit/Add links on About You and Your Practice
  section cards, the "Use a different email" link on OTP verify, the
  "Choose a plan" header link, the footer links, the Avo back-link, and
  the education page's Remove / Add another college controls. Dropdown
  menu items are unchanged — they keep their row-highlight hover.

### Added
- About You → Education page is now editable. Fields: `year_began_practice`
  (years of experience) plus up to two college/university entries with
  degree and graduation year. College picker is a WAI-ARIA combobox backed
  by a JSON search endpoint (`GET /about-you/colleges/search`). When a
  therapist can't find their school, the combobox offers an inline
  "Add '…' (pending review)" option that creates a `colleges` row with
  `status: "pending"` and attributes it to the submitting therapist. A
  "Pending review" badge renders next to any non-approved selection, both
  on the live dropdown and on the saved state.
- Year inputs (in-practice-since + graduation year) are plain 4-digit text
  boxes — no spinner arrows. `inputmode="numeric"`, `maxlength="4"`, and a
  new `digits-only` Stimulus controller strip any non-digits on the fly.
  Server-side, `Therapist#year_began_practice` and
  `TherapistEducation#graduation_year` must fall within 1940..current year
  (integer). `College` validates `name` presence + 120-char max and
  normalizes whitespace. `College.find_or_submit` case-insensitively
  matches existing names before creating a new pending row, preventing
  duplicate submissions.

### Changed
- Removed the dashboard page. Account Settings is now the landing page
  for signed-in users. Top nav "Dashboard" → "Your Account" linking to
  `/account-settings`. Logo, post-signin redirect, Avo admin redirect,
  and Avo header back-link all point to `account_settings_path`.
- Moved the Share button (profile-link dropdown) from the removed
  dashboard page into the layout header, positioned to the left of the
  avatar. Works on desktop; hidden under the mobile hamburger.
- Account Settings profile photo: added "Profile pic" label above the
  avatar, bumped avatar to 80×80, added upload icon to the Change
  button, removed the "JPEG or PNG. 5 MB max." helper text.
- Removed page titles (`content_for :page_header`) from every dashboard
  section page. Removed inner bordered box + "Your account" section
  title from the Account form; added a `border-t` divider above the
  Save button on the three editable forms (account, professional
  identity, primary credential).
- Fixed `account_settings_account_path` → `account_path` on the Account
  form (scope doesn't namespace URL helpers).

### Removed
- `DashboardController` and `app/views/dashboard/show.html.erb`.
- `dashboard` resource and `test_submit` route.
- Redundant "Account Settings" link from the avatar and mobile
  dropdowns (now covered by the top-nav "Your Account" item).

## 2026-04-16

### Added
- Admin panel using Avo (free/community edition) at `/avo`.
  Includes Avo resources for all core models (User, Therapist,
  Location, UserCredential, TherapistEducation,
  TherapistContinuingEducation, BusinessHour, ZipLookup) and all
  reference tables (Specialty, Service, Language, State, Profession,
  College, etc.). Access restricted to admin users via Supabase auth
  session + `is_admin` flag. Search enabled on all resources.
- Specialty and service category models, migrations, and Avo
  resources. SpecialtyCategory and ServiceCategory tables with
  join tables to associate specialties/services with their
  categories. Manageable through the admin panel.

## 2026-04-15

### Added
- Deep health check endpoint at `/health`
  ([`app/controllers/health_controller.rb`](app/controllers/health_controller.rb)).
  Validates DB connectivity and Solid Queue process readiness. Returns
  JSON `{"db":"ok","queue":"ok"}` with 200 when healthy, 503 when
  degraded. Safelisted from Rack::Attack throttling and silenced from
  Lograge request logs. Point a Better Stack uptime monitor at this
  endpoint.

### Changed
- Upgraded Sentry DSN missing-credential log from `info` to `warn` so
  it surfaces in Better Stack when error tracking is silently disabled
  in production.

## 2026-04-14

### Added
- Internal Discord notifications via `Notifier` service
  ([`app/services/notifier.rb`](app/services/notifier.rb)) and
  `NotifierJob` ([`app/jobs/notifier_job.rb`](app/jobs/notifier_job.rb)).
  Channel symbol → credentials webhook map is the single source of
  truth. Delivery is always async through SolidQueue; failed
  deliveries are logged (`event=notifier.delivery_failed`) and
  discarded with no retries. Unknown channel symbols raise
  `Notifier::UnknownChannel` at call time so typos are caught early.
  Wired initially for new signup (`:admin`) in
  `CreateAccountController#create` and for `Rack::Attack` throttle
  trips (`:admin`) with a 1-hour per-IP cooldown stored in
  `Rails.cache` so one scraper can't flood the channel.
- Better Stack Error tracking via the Sentry SDK (`sentry-ruby` +
  `sentry-rails`). Better Stack's setup page explicitly uses the
  Sentry SDK with a Better Stack DSN — no Better-Stack-specific gem
  exists. New [`config/initializers/sentry.rb`](config/initializers/sentry.rb)
  is production-only, reads `BETTER_STACK_ERRORS_DSN` from
  credentials, `traces_sample_rate: 0.0`, `send_default_pii: false`,
  `report_rescued_exceptions: false`. Captures uncaught exceptions
  from controllers, background jobs (SolidQueue via ActiveJob), and
  anywhere in app code.
- Uncaught exceptions are intentionally *not* routed to Discord.
  Better Stack's native alerting (email + mobile app) covers error
  triage for a solo dev, and Discord would just duplicate the signal
  in a worse format. The `#errors` channel and `ERRORS_WEBHOOK`
  credential stay in place, reserved for future manual use.
- [`_docs/_processes/notifications.md`](_docs/_processes/notifications.md)
  documenting the channel map, public API, what is currently wired,
  and the Better Stack error tracking setup checklist. Linked from
  the docs index.

- Rate limiting on auth endpoints via two layers:
  - Rails 8 `rate_limit` in `AuthController` — 5 signin attempts per IP per 15 min, 5 per email per hour, 10 verify attempts per IP per 15 min. Redirects back to the form with a readable flash on throttle.
  - `rack-attack` middleware with a global 300 req/5 min per IP safety net plus looser auth-specific throttles as a fallback. Returns plain `429` with `Retry-After` and logs `event=rack_attack.throttled`.
  - Counters stored in `Rails.cache` (Solid Cache in production, memory_store in development). Assets and `/up` safelisted; localhost safelisted in development.
  - Structured throttle logging: `auth.rate_limit.signin_ip`, `auth.rate_limit.signin_email`, and `auth.rate_limit.verify_ip` events from the Rails layer (via `auth_log`, with a 12-char SHA256 email fingerprint for the email-scoped throttle — raw emails never hit the logs). `rack_attack.throttled` event from the middleware layer.
  - [`_docs/_processes/rate-limiting.md`](_docs/_processes/rate-limiting.md) documents the policy, logging events, and what is intentionally not limited.
- Structured JSON request logging via `lograge`. One line per request with `request_id`, `user_id`, `duration`, `view`, `db`, `status`, `host`, and filtered `params`. Multi-line Rails default preserved in development for readability.
- Better Stack log shipping via `logtail-rails`. Enabled in every environment except `test` whenever `BETTER_STACK_SOURCE_TOKEN` and `BETTER_STACK_INGESTING_HOST` credentials are present; broadcasts alongside STDOUT so local tailing still works. Credentials stubbed in `credentials.example`.
- `append_info_to_payload` in `ApplicationController` surfaces `current_user.id` (never email) to lograge.
- Explicit dev log level (`debug`) and `:request_id` tag in `config/environments/development.rb`.
- [`_docs/_processes/logging.md`](_docs/_processes/logging.md) documenting log shape, filtering rules, and Better Stack setup.
- Structured `event=auth.*` log lines across the sign-in flow: OTP send/verify attempts and outcomes, session created/refreshed/invalid, profile gate redirect, and sign out. All PII-free — `user_id` only, never email or tokens.
- `auth_log` helper in `Authentication` concern: single entry point for auth/authz log lines, always stamps `ip` and `ua` automatically. Added `auth.user.created` event and `authz.denied` events from `require_auth` / `require_profile`.

### Changed
- `config/initializers/filter_parameter_logging.rb` — expanded filter list to cover `jwt`, `authorization`, `session`, `api_key`, `access_token`, `refresh_token`, `turnstile`, `cf-turnstile-response`, `phone`, `dob`, `address`, `zip`, `card`, `account_number`, `routing_number`.

### Fixed
- Profile photo uploads now read R2 settings with `fetch`, use explicit static credentials, and return a clear app error when R2 config is missing or blank.
- Prevented profile photo uploads from falling back to a developer's local AWS SSO credentials.
- Prevented the AWS SDK token provider from reading the developer's `AWS_PROFILE` SSO token during R2 client setup.
- Profile photo upload errors now point to R2 CORS when the browser blocks the direct upload step.
- The profile photo `Change` button now keeps its natural width instead of stretching across the upload status area.
- The top-right dashboard account avatar now shows the saved profile photo instead of staying on initials.

## 2026-04-13

### Added
- `GeocodeLocationJob` — background geocoding with three-stage fallback (perfect city match, state+zip, zip-only) using `zip_lookups` table
  - Enqueued after account creation in `CreateAccountController#create`
  - Prefers `city_lat`/`city_lng` over `zip_lat`/`zip_lng`
  - Tracks `city_match_successful`, `canonical_city`, `canonical_state`, `geocode_status`
  - Replaced inline `before_save` geocode callback on Location model
- R2 direct upload for profile photos via presigned URLs (no ActiveStorage)
  - `config/initializers/r2.rb` — S3 client configured for Cloudflare R2
  - `AccountSettings::PresignedUploadsController` — generates presigned PUT URLs with type/size validation
  - `AccountSettings::AccountsController#update` — saves validated image URL to therapist record
  - `profile_photo_upload` Stimulus controller — client-side file pick, validate, upload, and image swap
  - Route: `POST /account-settings/presigned-upload`, `PATCH /account-settings/account`
  - Added `aws-sdk-s3` gem
  - Added `R2_PUBLIC_URL` to credentials.example
