# Turnstile Guide

Use this guide before you change Turnstile or Turbo in the auth flow.

## What the app does right now

The current sign in flow works like this:

1. The sign in page renders Cloudflare Turnstile with the plain widget markup.
2. The widget writes its token into `session[cf-turnstile-response]`.
3. Rails applies a local sign in throttle before it reaches Supabase.
4. `SessionsController#create` reads that token and renames it to `turnstile_token`.
5. Rails sends that token to Supabase Auth when it posts to `/auth/v1/otp`.
6. Supabase Auth verifies the captcha during OTP send.
7. Rails does not run its own Turnstile verification before the OTP call.

This means Supabase owns captcha verification for the OTP send step in the current app.

## Files that make the current setup work

- `app/views/sessions/new.html.erb`
- `app/controllers/sessions_controller.rb`
- `app/services/supabase_auth_client.rb`
- `app/controllers/application_controller.rb`
- `app/javascript/controllers/signin_form_controller.js`
- `app/javascript/controllers/index.js`
- `app/javascript/application.js`
- `app/views/sessions/verify.html.erb`
- `test/integration/auth_flow_test.rb`

## Current sign in page setup

The sign in page in `app/views/sessions/new.html.erb` does these things:

- Loads `https://challenges.cloudflare.com/turnstile/v0/api.js` in the page head when a site key is present.
- Renders a `div` with `class="cf-turnstile"`.
- Uses `data-sitekey` from `turnstile_site_key`.
- Uses `data-theme="light"`.
- Uses `data-size="flexible"`.
- Uses `data-action="signin"`.
- Uses `data-response-field-name="session[cf-turnstile-response]"`.
- Turns Turbo off on the sign in form with `data-turbo="false"`.
- Attaches the `signin-form` Stimulus controller to the form.

The site key comes from `ApplicationController#turnstile_site_key`, which reads:

- `Rails.application.credentials[:TURNSTILE_SITE_KEY]`

## Current server side setup

`SessionsController#create` does these checks in order:

1. It applies the local sign in rate limits for IP address and normalized email address.
2. If one of those limits is hit, it re-renders the sign in page with `429 Too Many Requests`.
3. It normalizes the email address.
4. It reads the Turnstile token from `session[cf-turnstile-response]`.
5. It rejects the request if the email is blank.
6. It rejects the request if the Turnstile token is blank.
7. It calls `SupabaseAuthClient#send_email_otp`.

`SupabaseAuthClient#send_email_otp` sends this payload to Supabase:

```json
{
  "email": "person@example.com",
  "gotrue_meta_security": {
    "captcha_token": "token-from-turnstile"
  }
}
```

That is the only Turnstile verification path in the current auth flow.

The local Rails throttle is only a request guard.
It does not verify the Turnstile token.
It does not add a second captcha step.

## Important rule

Do not add a second Rails side Turnstile verification step back into `SessionsController#create`.

We already had a broken version of this flow where:

1. Rails validated the token.
2. Supabase Auth also tried to validate the same token for `/otp`.

That design caused trouble because the token is single use.

## The old verifier file

`lib/turnstile_verifier.rb` still exists in the repo.

It is not part of the current sign in flow.

Treat that file as old code unless you intentionally decide to move captcha verification back into Rails.

Do not use that file for the current Supabase owned OTP flow.

## Why Turbo is off on the auth forms

The app still has Turbo installed.

The app does not use Turbo for the sign in form or the verify code form.

The reason is simple:

- Turnstile renders correctly on a normal page load.
- A failed submit with Turbo can replace page content without a full reload.
- That can leave the captcha missing or stale.

The current fix is:

- Turn Turbo off on `app/views/sessions/new.html.erb`
- Turn Turbo off on `app/views/sessions/verify.html.erb`

## The Stimulus controller you also need

Turning Turbo off on the sign in form is not the only Turnstile related behavior in the app.

The sign in form also uses `app/javascript/controllers/signin_form_controller.js`.

The sign in form also uses `app/javascript/controllers/submit_button_controller.js`.

Those controllers split the work like this:

1. `signin_form_controller.js` resets the Turnstile widget after a failed submit when the page re-renders with an alert.
2. `submit_button_controller.js` shows the submit spinner and disables the clicked submit button after submit.

The controller is wired in through:

- `app/javascript/controllers/index.js`
- `app/javascript/application.js`

If you rebuild this setup, do not forget that controller.

## What to keep if you reimplement Turnstile

If you need to rebuild the current working setup, keep all of this:

- Cloudflare `api.js` loaded on the sign in page
- Plain `cf-turnstile` widget markup in the sign in view
- `data-response-field-name="session[cf-turnstile-response]"`
- `SessionsController#create` mapping that field to `turnstile_token`
- Supabase OTP send with `gotrue_meta_security.captcha_token`
- No separate Rails verification call
- The local Rails auth throttle before OTP send
- `data-turbo="false"` on the sign in form
- `data-turbo="false"` on the verify code form
- The `signin-form` Stimulus controller
- The `submit-button` Stimulus controller on auth forms
- Auth flow tests that cover success and captcha failure

## What to change if you remove Turbo from the whole app

Disabling Turbo on one form is not the same thing as removing Turbo from the app.

Right now Turbo is still installed in these places:

- `Gemfile` includes `gem "turbo-rails"`
- `package.json` includes `@hotwired/turbo-rails`
- `app/javascript/application.js` imports `@hotwired/turbo-rails`
- `app/views/layouts/application.html.erb` uses `data-turbo-track="reload"` on the asset tags

If you want to remove Turbo from the app entirely, do this:

1. Remove `gem "turbo-rails"` from `Gemfile`.
2. Run bundle install.
3. Remove `@hotwired/turbo-rails` from `package.json`.
4. Run yarn install.
5. Remove `import "@hotwired/turbo-rails"` from `app/javascript/application.js`.
6. Remove `data-turbo-track="reload"` from the layout asset tags in `app/views/layouts/application.html.erb`.
7. Search the repo for `turbo`, `Turbo`, `turbo_frame`, and `turbo_stream` and remove any leftover usage.
8. Rebuild assets and run tests.

If you remove Turbo from the app, Stimulus can stay.

Stimulus is separate from Turbo in this repo.

## CSP note

The current guide for this repo is still:

- Leave the app CSP off unless there is a clear reason to add it back.

We already hit CSP problems while debugging Turnstile.

If you add CSP back later, check the current Cloudflare Turnstile docs first and test the sign in flow again.

## Environment and credential notes

The current Rails code reads these values from credentials:

- `TURNSTILE_SITE_KEY`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Supabase OTP SMTP settings are not stored in Rails credentials.

Supabase uses its own configured SMTP provider for OTP emails.

Those SMTP credentials live in the Supabase dashboard.

Secure email change is currently off in Supabase.

That means the update email flow sends one OTP email to the new email address instead of one email to each address.

The current Rails sign in flow does not use `TURNSTILE_SECRET_KEY`.

That secret was used by the old Rails side verifier flow.

## Tests to keep in sync

Keep `test/integration/auth_flow_test.rb` in sync when you change this flow.

The current tests cover:

- successful sign in start
- captcha failure from Supabase
- local auth throttling before the OTP call
- auth forms submitting without Turbo

Add or update tests any time you change:

- Turnstile field names
- Turbo behavior on the auth forms
- Supabase OTP payload shape
- retry behavior after a failed sign in submit
- local auth throttling before the OTP call

## Rebuild checklist

If you need to implement the current working version again, use this checklist:

1. Put `TURNSTILE_SITE_KEY` in Rails credentials.
2. Put `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in Rails credentials.
3. Load Cloudflare `api.js` on the sign in page.
4. Render the Turnstile widget with the current `data-response-field-name`.
5. Post the sign in form with Turbo off.
6. Map `cf-turnstile-response` to `turnstile_token` in `SessionsController`.
7. Send the token to Supabase in `gotrue_meta_security.captcha_token`.
8. Do not verify the token a second time in Rails.
9. Keep the `signin-form` Stimulus controller connected.
10. Keep Turbo off on the verify code form.
11. Run the auth integration tests.

## Official docs to check before changing this again

- https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
- https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/widget-configurations/
- https://developers.cloudflare.com/turnstile/reference/content-security-policy/
- https://supabase.com/docs/guides/auth/auth-captcha
