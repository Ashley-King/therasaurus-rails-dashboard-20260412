# Google Auth Login Plan

**Date:** 2026-05-11
**Status:** Implemented in Rails; pending local and production OAuth QA

## Goal

Add Google sign-in next to the existing email code flow.

Email codes stay available. Passwords stay out of scope. Facebook stays out of scope.

Supabase Auth remains the identity system. Rails still owns the app session, the `users` table, and all access checks.

## Current State

- `/signin` shows `Continue with Google` above the email code form.
- `POST /signin` sends a Supabase email code.
- `POST /signin/google` starts the Supabase Google OAuth flow.
- `/signin/google/callback` exchanges the Supabase auth code for a Rails session.
- `/verify` checks the code.
- A successful email code login or Google login stores Supabase access and refresh tokens in the Rails session.
- Rails creates or finds a `User` row with the same UUID as the Supabase auth user.
- New users go to `/create-account`.
- Returning users go to `/account-settings`.
- Auth process docs, rate limit docs, and the changelog have been updated.

## Progress Log

### 2026-05-14

- Removed the returning-user `Welcome back!` flash after email-code and Google sign-in.
- Kept the purple admin membership preview banner visible by default.
- Removed the redundant yellow offline warning inside Account Settings because the purple membership banner already covers that state.
- Removed the skip-trial notice flash and the blue trial banner inside Account Settings.
- The purple membership banner now appears for `member` and `trialing_member` accounts, not only ended-trial users.
- The old Google OAuth client owned by `ashleyot@gmail.com` was deleted before deployment. Recreate the OAuth app while logged in as `ashley@therasaurus.org`.
- Use a managed Google Group, `auth-support@therasaurus.org`, as the Google OAuth user support email. Do not set that address up as a user alias if it needs to appear in Google's support email dropdown.
- Added a public Rails `/app-info` page for Google OAuth branding review.
- Use `https://app.therasaurus.org/app-info` as the Google OAuth application home page if Google rejects the marketing homepage.
- Added public Rails `/privacy-policy` and `/terms` pages.
- The `/app-info` page visibly explains the app purpose and links to the in-app privacy policy and terms pages.

### 2026-05-13

- Account settings raised a missing translation error for inferred Rails form labels after Google sign-in reached `/account-settings`.
- Fixed the reported account settings labels and two similar inferred labels on profile forms.
- RuboCop passed after the label fix.
- Added the Google mark to the `Continue with Google` button so the provider is visually identifiable.
- Google's sign-in page currently shows the Supabase project URL because Google sees Supabase Auth as the OAuth callback host.
- This is expected with the default Supabase project domain.
- Google OAuth app branding still needs to be configured and published if the Google screen should say `continue to Therasaurus`, like OpenAI's verified OAuth screen.
- Google OAuth support email cannot usually be a Gmail alias. Use a real Google Workspace user or a managed Google Group, such as `support@therasaurus.org`, if that address should appear on the consent screen.
- Because the app is not deployed yet, it is acceptable to replace the current Google OAuth client with a clean one owned by the `therasaurus.org` Workspace account. Update Supabase with the new client ID and secret, test locally, then delete the old Google OAuth client.
- To show a branded domain on Google's OAuth screen, configure a Supabase custom domain or vanity subdomain, add the new `/auth/v1/callback` URL to Google, and update the Rails `SUPABASE_URL` after activation.

### 2026-05-12

- Google OAuth routes added:
  - `POST /signin/google`
  - `GET /signin/google/callback`
- `SupabaseAuth` now builds the Google OAuth authorize URL and exchanges PKCE auth codes for Supabase sessions.
- `AuthController` now routes Google and email code sign-ins through the same Rails session and profile gate.
- The sign-in page now shows `Continue with Google` and keeps email code login.
- Rails and Rack::Attack rate limits now cover `POST /signin/google`.
- OAuth callback `code` is filtered from params.
- Verification passed:
  - `ruby -c app/controllers/auth_controller.rb`
  - `ruby -c app/services/supabase_auth.rb`
  - `bin/rails routes -g signin`
  - `bundle exec rubocop`
  - local browser check of `/signin`
  - local Google OAuth start reached Google sign-in
  - local request log shows `Cookie` and `Authorization` headers as `[FILTERED]`
- Logtail header filtering now filters `Authorization`, `Proxy-Authorization`, `Cookie`, and `Set-Cookie` headers before local logging or Better Stack shipping.

## Assumptions

- Google login should land in the same Rails session flow as email code login.
- A user who signs in with Google and later signs in with an email code should reach the same account when the email address is the same and verified.
- Rails should key users by Supabase user UUID, not by Google account ID.
- Rails should not manually merge two Rails users by email. If Supabase does not link the identities, stop and inspect Supabase before merging app data.
- The app should not store Google access tokens unless a later feature truly needs Google API access.
- The production app callback is `https://app.therasaurus.org/signin/google/callback` unless the deployment host changes before launch.
- Local development callback will likely be `http://localhost:3000/signin/google/callback`.

## Docs Checked

- Supabase Google OAuth: https://supabase.com/docs/guides/auth/social-login/auth-google
- Supabase redirect URLs: https://supabase.com/docs/guides/auth/redirect-urls
- Supabase PKCE flow: https://supabase.com/docs/guides/auth/sessions/pkce-flow
- Supabase identity linking: https://supabase.com/docs/guides/auth/auth-identity-linking
- Rails routing guide: https://guides.rubyonrails.org/routing.html

## Phase 1: Configure Google And Supabase

**Status:** User-completed, pending end-to-end production QA.

### Scope

Set up Google and Supabase so Supabase Auth can accept Google sign-ins and send users back to Rails.

### Why this phase comes now

The app code cannot be verified until Google and Supabase agree on allowed redirect URLs.

### Main changes

- Create or update the Google OAuth app in Google Cloud.
- Add the Supabase Auth callback URL to Google:
  - `https://<supabase-project-ref>.supabase.co/auth/v1/callback`
- Enable Google as a provider in Supabase Auth.
- Add Rails callback URLs to the Supabase redirect allow list:
  - `https://app.therasaurus.org/signin/google/callback`
  - `http://localhost:3000/signin/google/callback`
- Confirm Supabase settings report Google as enabled.

### Risks or edge cases

- A wrong Google redirect URL will fail before Rails sees the user.
- A wrong Supabase redirect allow-list entry will send the user to an auth error.
- If the production host changes, the Supabase allow list must be updated before launch.

### Validation

- Confirm Google is enabled in Supabase Auth settings.
- Confirm the exact local and production callback URLs are allow-listed.
- Confirm a manual redirect to Google starts from Supabase and returns to the Rails callback.

### Temporary inconsistency

Google may be enabled in Supabase before the Rails button is live. That is fine because users will not see a Google option yet.

## Phase 2: Add The Rails Google Login Path

**Status:** Implemented, pending full OAuth callback QA.

### Scope

Add the Rails routes and server-side callback handling for Google login.

### Why this phase comes now

The Rails server must own the final session. The browser should not decide whether a user is signed in.

### Main changes

- Add routes:
  - `POST /signin/google`
  - `GET /signin/google/callback`
- Add Google login handling to `AuthController`, unless the file becomes hard to read. If it does, use a small `GoogleAuthController`.
- Add `SupabaseAuth` methods for the Google OAuth start URL and callback code exchange.
- Use Supabase's PKCE flow.
- Store the Google PKCE code verifier in the Rails session before redirecting to Supabase.
- On callback:
  - reject a missing auth code or missing code verifier
  - handle provider errors
  - exchange the callback code for Supabase tokens
  - store the Supabase access and refresh tokens with `store_auth_session`
  - clear Google auth session scratch values
  - find or create the Rails `User` using the Supabase user UUID
  - route users through the same profile gate used by email code login
- Keep logs free of email addresses, codes, tokens, and Google user data.
- Add rate limiting for `POST /signin/google`.

### Risks or edge cases

- A callback can be replayed or opened without starting the flow. The PKCE code verifier check should reject that.
- The callback code expires quickly and can only be used once. Failed exchange should send the user back to `/signin`.
- Google may not return a usable email. Rails should show a friendly error instead of creating a broken user.
- Supabase should link Google and email-code identities by verified email. If it does not, do not merge Rails users by email in app code.
- The existing `User#email` value may not match a later Google email change. Do not update the Rails email from Google without a separate decision.

### Validation

- Starting Google login redirects to Supabase, then Google.
- Canceling at Google returns a clear error on `/signin`.
- Callback with missing auth code is rejected.
- Callback with missing code verifier is rejected.
- Successful Google login creates a Rails session.
- A new Google user without a therapist profile goes to `/create-account`.
- A returning Google user with a profile goes to `/account-settings`.
- A user who already used email code and then uses Google with the same verified email lands in the same Rails user UUID.

### Temporary inconsistency

The routes may exist before the button is visible. That is safe because the routes still require a valid OAuth callback.

## Phase 3: Update The Sign-In Page

**Status:** Implemented and locally checked.

### Scope

Show Google login as a clear option without making the email code flow harder to use.

### Why this phase comes now

The UI should only expose Google after the server-side flow exists.

### Main changes

- Add a `Continue with Google` button to `app/views/auth/new.html.erb`.
- Keep the email code form on the same page.
- Use plain copy:
  - `Continue with Google`
  - `Or sign in with email`
  - `We will send a code to your email. Enter the code on this site.`
- Use `POST /signin/google` for the Google button.
- Keep Turbo disabled for the auth forms.
- Make the Google button keyboard accessible.
- Keep visible focus styles.
- Do not add Facebook.
- Do not add passwords.

### Risks or edge cases

- Users may not understand that email code and Google can lead to the same account. Keep the page simple instead of explaining identity linking in the UI.
- A Google button can look like a secondary marketing CTA. It should look like a normal sign-in option.
- If Turnstile is added back later, keep it tied to email-code sending. Google login does not need the same OTP send step.

### Validation

- Keyboard users can reach and use both sign-in options.
- Focus styles are visible.
- Mobile layout does not crowd the email field or buttons.
- Email code flow still works unchanged.
- Google button does not submit the email form by accident.

### Temporary inconsistency

If the UI deploys before Supabase config is correct, Google login will fail. Avoid that by completing Phase 1 first.

## Phase 4: Update Docs, Tests, And Release Checks

**Status:** Partially complete.

### Scope

Document the new auth behavior and check the risky paths before showing this to therapists.

### Why this phase comes now

Auth bugs are expensive to debug after users start signing in.

### Main changes

- Update `_docs/_processes/auth.md` so it covers:
  - email code login
  - Google login
  - shared Rails session storage
  - shared profile gate
  - identity linking expectations
- Update `_docs/_processes/rate-limiting.md` if a new Google sign-in throttle is added.
- Update `CHANGELOG.md`.
- Add the smallest useful tests for:
  - Google callback state mismatch
  - Google callback success
  - existing Supabase user UUID reusing the existing Rails user
- If the test setup is not ready, write a manual QA checklist in the auth process doc before launch.
- Run RuboCop through `mise`.

### Risks or edge cases

- Test stubs can accidentally test fake behavior instead of the callback contract. Keep service tests close to the real Supabase response shape.
- Manual QA must include both new and returning users.
- The docs must not imply email code login is MFA. It is still one sign-in method. MFA is a separate future feature.

### Validation

- `mise exec -- bundle exec rubocop`
- Auth tests pass if tests are added.
- Manual QA passes in local development.
- Manual QA passes against the production Supabase project before public demos.

### Temporary inconsistency

The process doc is updated after implementation. This plan remains as the rollout and QA reference until production Google sign-in is manually verified.

## Rollback

- Hide or remove the Google button.
- Disable Google in Supabase Auth if needed.
- Keep email code login active.
- Do not delete Supabase identities or Rails users during rollback.

## Risks

- Supabase's OAuth REST details need to be checked during implementation because this Rails app talks to Supabase Auth directly instead of using `supabase-js`.
- Identity linking depends on verified email addresses. If a provider does not return a verified email, the account may not link.
- A callback URL mismatch is the most likely setup mistake.
- OAuth error messages can expose too much detail if passed through raw. Show friendly messages to users and log safe details.
- Adding Google reduces login friction, but it does not add MFA.

## Open Questions

- What exact production host should be allow-listed before launch?
- Should Google login appear above the email code form or below it?
- Should admin sign-in pages show Google, or should admins keep email code only for testing?
- Should we add a short support note for users who choose the wrong Google account?
