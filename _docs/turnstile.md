# Turnstile Guide

## Current status: NOT wired

Cloudflare Turnstile is **not currently used** in this app.

- The sign-in view ([`app/views/auth/new.html.erb`](../app/views/auth/new.html.erb))
  does not load the Turnstile script, render the widget, or include a
  `cf-turnstile-response` field.
- [`AuthController#create`](../app/controllers/auth_controller.rb) does not
  read a captcha token and does not pass `gotrue_meta_security.captcha_token`
  to Supabase. The `SupabaseAuth#send_otp` call has no captcha argument.
- There is no `SessionsController` and no `app/views/sessions/` directory in
  this app — sign-in lives entirely under `AuthController` / `app/views/auth/`.

The only Turnstile-related code that remains is the defensive parameter
filter in [`config/initializers/filter_parameter_logging.rb`](../config/initializers/filter_parameter_logging.rb)
(`:turnstile`, `:"cf-turnstile-response"`) so that if we ever do receive
those parameters they are scrubbed from logs.

## Why this is OK right now

Auth abuse is currently mitigated by two layers of rate limiting — see
[`_processes/rate-limiting.md`](./_processes/rate-limiting.md):

- Rails 8 `rate_limit` in `AuthController` (per-IP and per-email).
- `Rack::Attack` middleware as a fallback / outer wall.

Add Turnstile back if rate limiting alone stops being enough (e.g. a real
bot signs up successfully, distributed scraping evades the IP throttle).

## Rebuild checklist (if reintroducing Turnstile)

If you decide to put Turnstile back in front of the OTP send, do this:

1. Put `TURNSTILE_SITE_KEY` (and only that — no secret needed for the
   Supabase-verified flow) in Rails credentials.
2. Load Cloudflare `api.js` on the sign-in page when the site key is
   present.
3. Render the widget in `app/views/auth/new.html.erb` with a plain
   `<div class="cf-turnstile">`. Use `data-response-field-name="cf-turnstile-response"`
   so the token lands in `params[:"cf-turnstile-response"]`.
4. Read the token in `AuthController#create`, pass it through to
   `SupabaseAuth#send_otp` as a captcha token argument, and forward it to
   Supabase as `gotrue_meta_security.captcha_token`. **Do not** verify the
   token a second time in Rails — Supabase verifies it during OTP send.
5. Disable Turbo on the sign-in and verify forms (`data: { turbo: false }`)
   so a failed submit doesn't leave the captcha widget stale.
6. After a failed submit that re-renders with an alert, reset the Turnstile
   widget client-side (Stimulus controller pattern works here).
7. Enable Turnstile in the Supabase dashboard so the OTP endpoint enforces
   it server-side.

## Why no double verification

We previously had a flow where Rails verified the token *and* Supabase tried
to verify the same token at `/otp`. Cloudflare tokens are single-use, so the
second call always failed. If Turnstile comes back, only one side verifies
it — and that side is Supabase, because Supabase already has the
infrastructure for it.

## CSP note

The app currently runs without CSP. We hit CSP problems debugging Turnstile
the first time. If you add CSP back later, check the current Cloudflare
Turnstile docs for required directives and re-test the sign-in flow end to
end.

## Related docs

- https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
- https://supabase.com/docs/guides/auth/auth-captcha
- [`_processes/auth.md`](./_processes/auth.md) — current sign-in flow
- [`_processes/rate-limiting.md`](./_processes/rate-limiting.md) — what is
  doing the abuse-prevention work today
