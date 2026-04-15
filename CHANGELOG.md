# Changelog

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
