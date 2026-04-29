# Auth Process

How authentication works in Therasaurus from end to end. Supabase Auth handles identity (email OTP). Rails owns session storage, the `users` table, and the therapist profile gate.

Keep this doc up to date as the flow changes.

## Key components

- **Supabase Auth** — issues OTPs, verifies them, returns JWT access + refresh tokens. Also verifies Turnstile on the OTP send step.
- **`SupabaseAuth` service** (`app/services/supabase_auth.rb`) — thin wrapper for `send_otp`, `verify_otp`, `refresh_session`. Raises `SupabaseAuth::AuthError` on failure.
- **`AuthController`** (`app/controllers/auth_controller.rb`) — sign-in, verify, sign-out.
- **`Authentication` concern** (`app/controllers/concerns/authentication.rb`) — `current_user`, `current_therapist`, `signed_in?`, `require_auth`, `require_profile`, JWT decode + refresh.
- **`CreateAccountController`** — profile creation gate for new users.
- **`User`** — mirrors the Supabase auth user (same UUID as `auth.users.id`). Holds `is_admin`, `membership_status`.
- **`Therapist`** — the profile row. Presence of this row = "profile complete."

## Routes

| Method | Path             | Action                    |
| ------ | ---------------- | ------------------------- |
| GET    | `/signin`        | `auth#new`                |
| POST   | `/signin`        | `auth#create` (send OTP)  |
| GET    | `/verify`        | `auth#verify` (code form) |
| POST   | `/verify`        | `auth#confirm` (check OTP)|
| DELETE | `/signout`       | `auth#destroy`            |
| GET    | `/create-account`| `create_account#new`      |
| POST   | `/create-account`| `create_account#create`   |

`root "auth#new"` — unauthenticated visitors land on the sign-in page.

## Session storage

On successful OTP verification, `store_auth_session` writes to the Rails session:

- `session[:access_token]` — Supabase JWT
- `session[:refresh_token]` — Supabase refresh token
- `session[:user_id]` — Supabase user UUID

On every request, `current_user` decodes the JWT (unverified — Supabase issued it), pulls `sub`, and loads the matching `User` row. If the JWT is expired, it calls `SupabaseAuth#refresh_session` with the stored refresh token and re-stores the new pair. If refresh fails, the session is cleared and the user is treated as signed out.

> Never trust the browser for auth decisions. The server checks `signed_in?` / `require_auth` / `require_profile` on every protected action.

## Flow 1: Brand-new user (first ever sign-in)

1. User visits `/signin`, enters email. (Turnstile is not currently wired — see [`turnstile.md`](../turnstile.md).)
2. `AuthController#create` calls `SupabaseAuth#send_otp(email)`. On success, the email is stashed in `session[:pending_email]` and the user is redirected to `/verify`.
3. User enters the 6-digit code. `AuthController#confirm` calls `SupabaseAuth#verify_otp`.
4. On success:
   - Tokens stored in session via `store_auth_session`.
   - `session[:pending_email]` cleared.
   - `find_or_create_user!` creates a `User` row keyed by the Supabase UUID. `is_admin` is set if the email is in `admin_emails`; `membership_status` defaults to `"member"` (or `"pro"` for admins).
5. `profile_complete?` returns false (no `therapist` row yet) → redirect to `/create-account`.
6. User fills out the create-account form. `CreateAccountController#create` validates, then inside a transaction creates the `Therapist` + initial `Location`, generates a unique `profile_slug` and `unique_id`. The location is geocoded synchronously when possible via the `Geocodable` concern; only unresolved ZIPs flip to `pending` and enqueue `GeocodeLocationJob`. See [`locations.md`](./locations.md).
7. Redirect to `/account-settings` (the post-signin landing page).

## Flow 2: Established user (returning, profile already exists)

1. User visits `/signin`, enters email → OTP sent.
2. User enters code → `AuthController#confirm` verifies, stores tokens, `find_or_create_user!` finds the existing `User`.
3. `profile_complete?` returns true (`current_therapist` present) → redirect to `/account-settings` with "Welcome back!".

## Flow 3: Already-signed-in user hits `/signin` or `/verify`

`redirect_if_signed_in` (before_action on `new`, `create`, `verify`, `confirm`):

- Admins are allowed to stay on the auth pages (useful for impersonation / testing).
- Non-admins with a complete profile are bounced to `/account-settings`.
- Non-admins without a profile fall through — they can re-verify, but the normal path is that they finish create-account.

## Flow 4: Sign-out

1. User hits `DELETE /signout`.
2. `AuthController#destroy` calls `reset_session` (clears access/refresh tokens and everything else) and redirects to `/signin` with a notice.
3. No call to Supabase — the tokens are simply forgotten server-side. Supabase tokens remain valid until their natural expiry, but the browser no longer holds them.

## Flow 5: Expired access token mid-session

1. Request comes in. `load_current_user` decodes the JWT and finds it expired (`JWT.decode` returns nil payload via `decode_jwt` — any decode error).
2. `handle_expired_token` tries `SupabaseAuth#refresh_session` with `session[:refresh_token]`.
3. On success, new tokens are stored and the request proceeds with the refreshed `current_user`.
4. On failure (or missing refresh token), the session is cleared and `current_user` returns nil. The next `require_auth` redirects to `/signin`.

## Guards used by protected controllers

- `require_auth` — redirects to `/signin` if not signed in. Use on anything that needs a user.
- `require_profile` — redirects to `/create-account` if signed in but no therapist row. Used by all `account_settings` / `about_you` / `your_practice` nested controllers.

## Turnstile

Turnstile is **not currently wired** into the auth flow. The sign-in form (`app/views/auth/new.html.erb`) does not render the widget and `AuthController#create` does not pass a captcha token to Supabase. See [`turnstile.md`](../turnstile.md) for the rebuild checklist if it needs to come back.

## Things this doc intentionally leaves out

- OTP expiry / rate limits — owned by Supabase config.
- Password auth — not used.
- Social auth — not used.

## Related docs

- [`turnstile.md`](../turnstile.md) — captcha setup
- [`business-rules.md`](../business-rules.md) — account + membership rules
- [`background-jobs.md`](../background-jobs.md) — includes `GeocodeLocationJob`
