# Billing and Email Review Fixes Plan

**Date:** 2026-05-03
**Status:** Billing webhook and Rails email delivery fixes complete; Supabase email-change flow pending

## Progress

- [x] Phase 1: Rails app and billing emails send through Resend SMTP in development and production.
- [x] Phase 2: billing state reads.
- [x] Phase 3: checkout failure handling.
- [x] Phase 4: webhook retry behavior.
- [x] Phase 5: webhook side-effect dedupe.
- [ ] Phase 6: pending. Supabase Auth sends the email-change email; Rails only starts, verifies, resends, and cancels the flow.
- [ ] Phase 7: pending. Final docs and checks after the remaining email and auth flow work.

## Goal

Fix the billing, webhook, email, and documentation issues from the May 2026 review without adding broad infrastructure or enterprise patterns.

The result should be:

- Production Rails emails send through Resend and use the real app host.
- Pay and Stripe failures show friendly errors where users can recover.
- Stripe webhook side effects are safe to retry and safe to receive more than once.
- Billing UI and Avo read the current Pay-backed billing model.
- The email change flow matches the product rules and uses Supabase Auth for the email-change email.
- Auth docs match the 8-digit Supabase OTP configuration.

## Assumptions

- Stripe billing continues to go through Pay.
- Stripe remains the only payment provider.
- Resend remains the Rails transactional email provider for Rails app and billing emails.
- Supabase Auth sends sign-in and email-change emails through its own configured SMTP provider.
- Supabase Auth is configured with 8-digit email OTPs in the hosted project.
- The app is not deployed yet, so migrations can be small and direct.
- We should not build a large event processing framework.

## Docs Checked

- Stripe webhook docs: duplicate events, asynchronous processing, and webhook retries.
- Rails Action Mailer docs: host configuration and SMTP delivery.
- Rails Active Job docs: failed jobs do not retry unless retry rules are configured.
- Resend Rails SMTP docs.
- Supabase Auth docs: email OTP length is configurable from 6 to 10 digits.
- Supabase Auth docs: updating a user's email sends the email-change message, and existing email-change OTPs can be resent.

## Phase 1: Fix Production Email Delivery

### Scope

Make Rails production app and billing emails use the real host and Resend SMTP. Development also sends live Rails email through Resend by project rule.

### Why this phase comes now

This is the highest-risk launch blocker for Rails-owned email. Emails with wrong links can send users to the wrong site. Missing delivery config can prevent billing and app emails from sending.

### Main changes

| File | Change |
|---|---|
| `config/environments/production.rb` | Set `config.action_mailer.default_url_options` to the real production host. Configure Action Mailer to send through Resend SMTP. Raise delivery errors in production. |
| `credentials.example` | Make sure the Resend credential name matches the production config. |
| `_docs/_processes/notifications.md` or a new email process doc | Document how Rails email is sent and what credential is required. |
| `CHANGELOG.md` | Add the production email configuration change. |

### Implementation notes

- Use `Rails.application.credentials.fetch(:RESEND_API_KEY)` so a missing key fails loudly.
- Use the verified TheraSaurus sender domain.
- Keep Supabase Auth emails separate from Rails emails. Supabase sends sign-in and email-change emails. Rails sends app and billing emails.

### Risks or edge cases

- If the production host is wrong, every generated email link is wrong.
- If the Resend sender domain is not verified, Resend can reject mail.
- If delivery errors are raised and Resend is misconfigured, bad deploys will fail loudly. That is better than silent email loss.

### Validation

- In a production-like console, generate `membership_url` and confirm it uses the real host.
- Send a Rails test email through Resend.
- Trigger `PlanChangeScheduledMailer` in a safe local or staging path.
- Confirm a missing `RESEND_API_KEY` fails boot or mail delivery loudly.

### Temporary inconsistency

None.

## Phase 2: Clean Up Current Billing State Reads

### Scope

Remove old billing state reads that still assume the pre-Pay columns and old membership names.

### Why this phase comes now

These are small changes with direct user-facing impact. They are safer to do before deeper webhook work.

### Main changes

| File | Change |
|---|---|
| `app/views/layouts/dashboard.html.erb` | Replace old `pro` and `trial` checks with `pro_member` and `trialing_member`. Read trial dates from Pay subscriptions when needed. |
| `app/avo/resources/user.rb` | Remove `stripe_customer_id` and `trial_ends_at` fields from the User resource. Add Pay-backed billing fields only if Avo supports them cleanly. |
| `app/controllers/auth_controller.rb` | Change admin-created users from `membership_status: "pro"` to `membership_status: "pro_member"`, or confirm admins should stay outside normal billing states. |
| `_docs/_processes/stripe.md` | Confirm the documented membership status mapping matches the code. |
| `CHANGELOG.md` | Add the billing state cleanup. |

### Risks or edge cases

- Admin users may use a special billing path. Decide whether admins should be `pro_member` or stay `member` with `is_admin` bypasses.
- Removing Avo fields can hide useful Stripe IDs unless Pay associations are exposed somewhere else.

### Validation

- A `pro_member` user does not see the choose-a-plan banner.
- A `trialing_member` user does not see the choose-a-plan banner.
- A `member` user still sees the correct banner.
- Avo User index and User detail pages load.
- Admin sign-in still works.

### Temporary inconsistency

None.

## Phase 3: Make Checkout Failures User-Safe

### Scope

Make the first checkout path rescue the error class Pay raises during customer creation.

### Why this phase comes now

It is small and protects the first paid action a therapist takes.

### Main changes

| File | Change |
|---|---|
| `app/controllers/start_trial_controller.rb` | Rescue both `Stripe::StripeError` and `Pay::Stripe::Error`. Keep the existing user-facing message and Stripe error notification. |
| `CHANGELOG.md` | Add the checkout error handling fix. |

### Risks or edge cases

- Rescuing too broadly can hide app bugs. Keep the rescue limited to Stripe and Pay Stripe errors.
- The notifier itself could fail. That should not stop the user from seeing the friendly message.

### Validation

- Stub Pay customer creation to raise `Pay::Stripe::Error`.
- Confirm the user is redirected back to `/start-trial` with the friendly alert.
- Confirm the Stripe error notification path is attempted.
- Confirm a normal checkout still redirects to Stripe Checkout.

### Temporary inconsistency

None.

## Phase 4: Make Webhook Processing Retryable

### Scope

Add retry behavior for transient failures in jobs that process billing webhooks.

### Why this phase comes now

Pay returns `200` after it stores and enqueues the webhook. Stripe will not retry if the later background job fails. The app needs its own retry path.

### Main changes

| File | Change |
|---|---|
| `app/jobs/application_job.rb` or a small Pay webhook job initializer | Add retry rules for transient failures that can affect Pay webhook processing. |
| `_docs/_processes/stripe.md` | Update webhook processing notes. Remove the incorrect statement that Pay dedupes by Stripe event id. |
| `_docs/background-jobs.md` | Document Pay webhook job retry behavior. |
| `CHANGELOG.md` | Add the webhook retry change. |

### Implementation notes

- Prefer narrow retry rules over retrying every `StandardError`.
- Include likely transient classes such as Stripe API errors, mail delivery network errors, database deadlocks, and temporary database connection errors.
- Do not retry known bad input forever.
- Keep `NotifierJob` behavior separate if it intentionally does not retry Discord failures.

### Risks or edge cases

- Retrying too broadly can repeat non-recoverable bugs.
- Retrying too narrowly can still drop important billing state updates.
- If the Pay webhook row is deleted after success, retries must only happen before successful processing finishes.

### Validation

- Force a transient error inside a Pay webhook subscriber.
- Confirm the job retries.
- Confirm the Pay webhook row remains available until the retry succeeds.
- Confirm permanent failures still reach Better Stack or the configured error notifier.

### Temporary inconsistency

During this phase, webhook jobs may retry, but app-side side effects may still repeat if Stripe sends duplicate events. Phase 5 removes that remaining risk.

## Phase 5: Dedupe Stripe Webhook Side Effects

### Scope

Prevent duplicate user emails and duplicate admin notifications when Stripe sends the same event more than once.

### Why this phase comes now

Retries from Phase 4 make failures safer, but duplicate Stripe deliveries still need a separate guard.

### Main changes

| File | Change |
|---|---|
| New migration | Add a small table for processed app-side Stripe webhook events. Store Stripe event id, event type, status, and timestamps. Add a unique index on Stripe event id and event type. |
| New model or service | Add one small helper that runs an app-side webhook side effect once per Stripe event. |
| `config/initializers/billing_subscribers.rb` | Wrap email and notification side effects with the once-per-event helper. Keep `BillingSync.sync_membership_status!` safe to run more than once. |
| `_docs/_processes/stripe.md` | Document app-side dedupe separately from Pay's own sync behavior. |
| `CHANGELOG.md` | Add the webhook dedupe change. |

### Implementation notes

- Do not patch Pay internals unless a simple app-owned receipt table fails.
- Mark a side effect complete only after it has been queued or sent.
- If a side effect fails, leave the receipt retryable.
- Keep the helper small and specific to Stripe app-side webhooks.

### Risks or edge cases

- If the receipt is marked complete before email enqueue succeeds, the email can be lost.
- If two duplicate deliveries run at the same time, the unique index must decide which one proceeds.
- Stripe can also create two different events for the same underlying object. For plan-change emails, event id dedupe prevents exact repeats. Object-level dedupe may be added only if duplicate user emails still happen.

### Validation

- Run the same `subscription_schedule.created` event twice.
- Confirm only one `PlanChangeScheduledMailer` is queued.
- Run the same cancellation event twice.
- Confirm only one admin cancellation notification is sent.
- Confirm `BillingSync.sync_membership_status!` remains safe if called more than once.

### Temporary inconsistency

The new receipt table will only know about events processed after deployment. Old events do not need backfill because the app has not launched.

## Phase 6: Finish the Supabase Email Change Flow

### Scope

Make the account email change flow match the business rules. Supabase Auth sends the email-change email through its configured SMTP provider. Rails does not send an email-change confirmation email.

### Why this phase comes now

This is user-facing account behavior, but it is less risky than production Rails email delivery and billing state.

### Main changes

| File | Change |
|---|---|
| `app/controllers/account_settings/update_emails_controller.rb` | Preserve `session[:pending_new_email]` across reloads and navigation. Add a resend action that asks Supabase to resend the email-change code. Keep cancel explicit. |
| `config/routes.rb` | Add a resend route under `/account-settings/update-email`. |
| `app/services/supabase_auth.rb` | Add a resend email-change method using the official Supabase resend flow, or safely call the existing Supabase email-change request again if confirmed by docs. Do not send this email through Rails. |
| `app/views/account_settings/update_emails/show.html.erb` | Add a resend button and simple timer copy. Keep the OTP input at 8 digits. |
| `_docs/business-rules.md` | Confirm the final behavior matches the rules. |
| `_docs/_processes/auth.md` | Document the 8-digit OTP behavior for sign-in and email change. Document that Supabase sends email-change emails, not Rails. |
| `_docs/_processes/rate-limiting.md` | Update the OTP brute-force note from 6 digits to 8 digits. Add the resend limit. |
| `CHANGELOG.md` | Add the email change flow fix. |

### Implementation notes

- Rails starts the change by calling Supabase Auth with the signed-in user's access token and the new email.
- Rails verifies the OTP by calling Supabase Auth.
- Rails updates `users.email` only after Supabase verifies the email-change code.
- Rails resend should call Supabase. It should not enqueue or deliver a Rails email.
- Keep Supabase Auth emails separate from Rails emails. Supabase owns auth and email-change emails. Rails owns app and billing emails.

### Risks or edge cases

- Supabase email-change sends can be abused if rate limits are too loose.
- Preserving pending email state can confuse users if the code expires. The page should let them resend or cancel.
- Supabase may return different errors for wrong, expired, or rate-limited codes. The UI should show the plain message without leaking sensitive details.

### Validation

- Start an email change, navigate away, return, and confirm the pending state is still shown.
- Refresh the page and confirm the pending state is still shown.
- Cancel the pending change and confirm the form resets.
- Resend a code through Supabase and confirm rate limiting works.
- Enter a wrong code and confirm a clear error is shown.
- Enter an expired code and confirm a clear error is shown.
- Enter a valid 8-digit code and confirm the Rails user email updates.
- Confirm no Rails email is sent for the email-change flow.

### Temporary inconsistency

None after this phase. During implementation, routes and UI should land together so users do not see a resend button before the backend exists.

## Phase 7: Final Documentation and Regression Check

### Scope

Make sure the docs and tests match the final behavior.

### Why this phase comes last

Earlier phases change behavior. Final docs and checks should describe what actually shipped.

### Main changes

| File | Change |
|---|---|
| `_docs/_processes/stripe.md` | Finalize Pay, webhook retry, and dedupe notes. |
| `_docs/_processes/auth.md` | Finalize OTP and email-change notes. |
| `_docs/business-rules.md` | Confirm no stale email-change requirements remain. |
| `_docs/background-jobs.md` | Mention Pay webhook job behavior if changed. |
| `CHANGELOG.md` | Add all shipped changes under the current date. |

### Validation

- Run the focused tests that cover touched behavior.
- Run `mise exec -- bundle exec rubocop`.
- Manually check the account settings email flow.
- Manually check membership banner states.
- Manually check Avo User page.
- Run a local Stripe CLI webhook replay for the touched webhook paths if credentials are available.

### Temporary inconsistency

None.

## Suggested Order

1. Phase 1: production Rails email config for app and billing emails.
2. Phase 2: billing state and Avo cleanup.
3. Phase 3: checkout error rescue.
4. Phase 4: webhook retry behavior.
5. Phase 5: webhook side-effect dedupe.
6. Phase 6: Supabase email change flow.
7. Phase 7: final docs and checks.

## Risks

- Webhook dedupe is the easiest place to accidentally drop a side effect. The receipt should be marked complete only after the work has been queued or sent.
- Retrying webhook jobs can repeat side effects if dedupe is not in place. Phase 5 should follow Phase 4 closely.
- Rails email delivery config depends on Resend account setup outside Rails.
- Supabase email-change delivery depends on Supabase Auth SMTP setup outside Rails.
- Supabase hosted settings are outside the repo. The app should document that hosted email OTP length is 8.

## Open Questions

- What exact production host should Rails use for generated links: `therasaurus.org` or `www.therasaurus.org`?
- Should admin users be stored as `pro_member`, or should admins stay `member` and bypass billing checks through `is_admin`?
- Should Rails use Resend SMTP or the Resend Ruby delivery method? SMTP avoids adding a gem. The Ruby delivery method is also official.
- Should duplicate plan-change emails be deduped only by Stripe event id, or also by Subscription Schedule id?
