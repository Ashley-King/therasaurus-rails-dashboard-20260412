# Turnstile Guide

## Current status

Cloudflare Turnstile is used in two places:

- Email-code sign-in at [`/signin`](../app/views/auth/new.html.erb).
- Public therapist message sends in
  [`Api::V1::TherapistMessagesController`](../app/controllers/api/v1/therapist_messages_controller.rb).

## Email-code sign-in

Turnstile belongs on the OTP send step only.

1. `app/views/auth/new.html.erb` loads Cloudflare `api.js`.
2. The sign-in form renders a plain `<div class="cf-turnstile">` with
   `data-response-field-name="cf-turnstile-response"`.
3. `AuthController#create` reads `params[:"cf-turnstile-response"]`.
4. `SupabaseAuth#send_otp` sends the token to Supabase as
   `gotrue_meta_security.captcha_token`.
5. Supabase verifies the token during OTP send.

Rails only checks that a token is present before it calls Supabase. Rails
does not verify the token for OTP send.

Google sign-in does not use Turnstile because it does not send an OTP.

The sign-in and verify forms both disable Turbo with `data: { turbo: false }`.
That keeps Turnstile and OTP form state simple after failed submissions.

## Therapist messages

The public therapist message API verifies Turnstile in Rails with
[`TurnstileVerifier`](../app/services/turnstile_verifier.rb). That flow is
separate from sign-in because it does not call Supabase Auth.

## Required config

- `TURNSTILE_SITE_KEY` in Rails credentials for the sign-in page.
- `TURNSTILE_SECRET_KEY` in Rails credentials for Rails-verified therapist
  messages.
- Supabase dashboard CAPTCHA protection enabled with Cloudflare Turnstile for
  Auth OTP sends.

## Why no double verification

We previously had a flow where Rails verified the token *and* Supabase tried
to verify the same token at `/otp`. Cloudflare tokens are single-use, so the
second call always failed. If Turnstile comes back, only one side verifies
it — and that side is Supabase, because Supabase already has the
infrastructure for it.

## CSP note

The app currently runs without an enforced CSP. If you add CSP back later,
check the current Cloudflare Turnstile docs for required directives and
re-test the sign-in flow end to end.

## Related docs

- https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
- https://supabase.com/docs/guides/auth/auth-captcha
- [`_processes/auth.md`](./_processes/auth.md) — current sign-in flow
- [`_processes/rate-limiting.md`](./_processes/rate-limiting.md) — what is
  doing the abuse-prevention work today
