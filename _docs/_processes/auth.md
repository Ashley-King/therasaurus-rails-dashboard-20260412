# Auth Process

How authentication works in Therasaurus from end to end. Supabase Auth handles identity through email OTP and Google OAuth. Rails owns session storage, the `users` table, and the therapist profile gate.

Keep this doc up to date as the flow changes.

## Key components

- **Supabase Auth** — issues OTPs, verifies them, handles Google OAuth, returns JWT access + refresh tokens. Also verifies Turnstile on the OTP send step when Turnstile is wired.
- **`SupabaseAuth` service** (`app/services/supabase_auth.rb`) — thin wrapper for `send_otp`, `verify_otp`, Google OAuth authorize URLs, PKCE code exchange, and `refresh_session`. Raises `SupabaseAuth::AuthError` on failure.
- **`AuthController`** (`app/controllers/auth_controller.rb`) — email code sign-in, Google sign-in, verify, sign-out.
- **`Authentication` concern** (`app/controllers/concerns/authentication.rb`) — `current_user`, `current_therapist`, `signed_in?`, `require_auth`, `require_profile`, JWT decode + refresh.
- **`CreateAccountController`** — profile creation gate for new users.
- **`User`** — mirrors the Supabase auth user (same UUID as `auth.users.id`). Holds `is_admin`, `membership_status`.
- **`Therapist`** — the profile row. Presence of this row = "profile complete."

## Routes

| Method | Path             | Action                    |
| ------ | ---------------- | ------------------------- |
| GET    | `/signin`        | `auth#new`                |
| POST   | `/signin`        | `auth#create` (send OTP)  |
| POST   | `/signin/google` | `auth#google` (start Google OAuth) |
| GET    | `/signin/google/callback` | `auth#google_callback` (finish Google OAuth) |
| GET    | `/verify`        | `auth#verify` (code form) |
| POST   | `/verify`        | `auth#confirm` (check OTP)|
| DELETE | `/signout`       | `auth#destroy`            |
| GET    | `/app-info`      | `public_pages#app_info` (public Google review page) |
| GET    | `/privacy-policy`| `public_pages#privacy_policy` |
| GET    | `/terms`         | `public_pages#terms`      |
| GET    | `/create-account`| `create_account#new`      |
| POST   | `/create-account`| `create_account#create`   |

`root "auth#new"` — unauthenticated visitors land on the sign-in page.

## Session storage

On successful email OTP verification or Google OAuth callback, `store_auth_session` writes to the Rails session:

- `session[:access_token]` — Supabase JWT
- `session[:refresh_token]` — Supabase refresh token
- `session[:user_id]` — Supabase user UUID

During Google OAuth, Rails also stores `session[:google_oauth_code_verifier]` until the callback exchanges the Supabase auth code for a session. It is deleted after success or failure.

On every request, `current_user` decodes the JWT (unverified — Supabase issued it), pulls `sub`, and loads the matching `User` row. If the JWT is expired, it calls `SupabaseAuth#refresh_session` with the stored refresh token and re-stores the new pair. If refresh fails, the session is cleared and the user is treated as signed out.

> Never trust the browser for auth decisions. The server checks `signed_in?` / `require_auth` / `require_profile` on every protected action.

## Flow 1: Brand-new user with email code

1. User visits `/signin`, enters email. (Turnstile is not currently wired — see [`turnstile.md`](../turnstile.md).)
2. `AuthController#create` calls `SupabaseAuth#send_otp(email)`. On success, the email is stashed in `session[:pending_email]` and the user is redirected to `/verify`.
3. User enters the 8-digit code. `AuthController#confirm` calls `SupabaseAuth#verify_otp`.
4. On success:
   - Tokens stored in session via `store_auth_session`.
   - `session[:pending_email]` cleared.
   - `find_or_create_user!` creates a `User` row keyed by the Supabase UUID. `is_admin` is set if the email is in `admin_emails`; `membership_status` defaults to `"member"` (or `"pro_member"` for admins).
5. `profile_complete?` returns false (no `therapist` row yet) → redirect to `/create-account`.
6. User fills out the create-account form. `CreateAccountController#create` validates, then inside a transaction creates the `Therapist` + initial `Location`, generates a unique `profile_slug` and `unique_id`. The location is geocoded synchronously when possible via the `Geocodable` concern; only unresolved ZIPs flip to `pending` and enqueue `GeocodeLocationJob`. See [`locations.md`](./locations.md).
7. Redirect to `/account-settings` (the post-signin landing page).

## Flow 2: Brand-new or returning user with Google

1. User visits `/signin` and chooses `Continue with Google`.
2. `AuthController#google` creates a PKCE code verifier and challenge, stores the verifier in the Rails session, and redirects to Supabase Auth.
3. Supabase sends the user to Google.
4. Google returns the user to Supabase.
5. Supabase returns the user to `/signin/google/callback` with a short-lived auth code.
6. `AuthController#google_callback` exchanges the auth code and code verifier for Supabase access + refresh tokens.
7. Rails creates or finds the `User` row keyed by the Supabase UUID.
8. If `profile_complete?` is false, redirect to `/create-account`.
9. If `profile_complete?` is true, redirect to `/account-settings`.

Supabase is expected to link Google and email-code identities when the verified email address is the same. Rails does not merge users by email.

Google OAuth branding may use `/app-info` as the application home page when Google needs a public page that explains the app purpose and links to `/privacy-policy` and `/terms`.

## Flow 3: Established email-code user (returning, profile already exists)

1. User visits `/signin`, enters email → OTP sent.
2. User enters code → `AuthController#confirm` verifies, stores tokens, `find_or_create_user!` finds the existing `User`.
3. `profile_complete?` returns true (`current_therapist` present) → redirect to `/account-settings`.

## Flow 4: Already-signed-in user hits `/signin`, `/signin/google`, or `/verify`

`redirect_if_signed_in` (before_action on `new`, `create`, `verify`, `confirm`, `google`):

- Admins are allowed to stay on the auth pages (useful for impersonation / testing).
- Non-admins with a complete profile are bounced to `/account-settings`.
- Non-admins without a profile fall through — they can re-verify, but the normal path is that they finish create-account.

## Flow 5: Sign-out

1. User hits `DELETE /signout`.
2. `AuthController#destroy` calls `reset_session` (clears access/refresh tokens and everything else) and redirects to `/signin` with a notice.
3. No call to Supabase — the tokens are simply forgotten server-side. Supabase tokens remain valid until their natural expiry, but the browser no longer holds them.

## Flow 6: Expired access token mid-session

1. Request comes in. `load_current_user` decodes the JWT and finds it expired (`JWT.decode` returns nil payload via `decode_jwt` — any decode error).
2. `handle_expired_token` tries `SupabaseAuth#refresh_session` with `session[:refresh_token]`.
3. On success, new tokens are stored and the request proceeds with the refreshed `current_user`.
4. On failure (or missing refresh token), the session is cleared and `current_user` returns nil. The next `require_auth` redirects to `/signin`.

## Guards used by protected controllers

- `require_auth` — redirects to `/signin` if not signed in. Use on anything that needs a user.
- `require_profile` — redirects to `/create-account` if signed in but no therapist row. Used by all `account_settings` / `about_you` / `your_practice` nested controllers.

## Turnstile

Turnstile is **not currently wired** into the auth flow. The sign-in form (`app/views/auth/new.html.erb`) does not render the widget and `AuthController#create` does not pass a captcha token to Supabase. See [`turnstile.md`](../turnstile.md) for the rebuild checklist if it needs to come back.

If Turnstile is added back later, it belongs on the email-code send step. Google sign-in does not send an OTP.

## Things this doc intentionally leaves out

- OTP expiry / rate limits — owned by Supabase config.
- Password auth — not used.
- Facebook auth — not used.
- MFA — not used yet. Email code and Google are sign-in methods, not second factors.

## Related docs

- [`turnstile.md`](../turnstile.md) — captcha setup
- [`business-rules.md`](../business-rules.md) — account + membership rules
- [`background-jobs.md`](../background-jobs.md) — includes `GeocodeLocationJob`
