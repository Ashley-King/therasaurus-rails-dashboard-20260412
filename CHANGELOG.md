# Changelog

## 2026-04-14

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
