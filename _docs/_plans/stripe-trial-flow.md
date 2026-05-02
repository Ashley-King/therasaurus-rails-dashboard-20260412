# Stripe Trial + Checkout Flow Plan

**Date:** 2026-04-30
**Status:** Draft

## Goal

Build the full post-signup billing funnel described in
[`_docs/business-rules.md`](../business-rules.md), Sections 5–7 and the
Trial / Billing rules:

1. After Create Account, the therapist lands on a `Start Your Trial`
   interstitial with the value-prop copy.
2. The therapist either starts a 14-day free trial via Stripe Checkout
   (card required) or skips and lands on Account Settings without a
   card on file.
3. After successful checkout, Stripe's `success_url` sends the
   therapist to an app-owned `Trial Started` landing page that
   tolerates webhook lag, then forwards to Account Settings.
4. Account Settings shows a `trialing` notification (with trial-end
   and card-charge dates) for trialing therapists, or a "start your
   free trial today" notification for therapists without an active
   trial or paid subscription.
5. Trialing and pro therapists' public profiles are online; therapists
   who skipped checkout are not public.
6. Stripe is the source of truth for billing state; the app derives
   `membership_status` from Stripe events.
7. The therapist gets Stripe's pre-charge email AND an app-sent
   reminder before the first charge.
8. The dev team gets a Discord ping when a therapist cancels or
   reactivates.

The build follows the project rule of "simple, reliable, easily
maintainable, secure, production-ready" and uses standard Rails +
Stripe patterns. No multi-tenant or enterprise scaffolding.

## Assumptions

- Stripe is the only billing provider. Live + test modes only.
- The `users` table already has `membership_status` (default
  `"member"`), `stripe_customer_id`, and `trial_ends_at`. We add the
  remaining columns we need; we do not redesign what is there.
- Membership state lives on `users`, not `therapists`. (One billing
  identity per signed-in user.)
- The Notifier service (`:admin`, `:stripe_errors`) is already wired
  for Discord. We reuse it instead of building anything new.
- Resend is the email provider; ActionMailer is already configured.
- Profile public-visibility is already derived from
  `membership_status` + account status + profile-complete in business
  rules. We do not change that derivation; we change the inputs.
- Webhooks run synchronously in the request to verify the signature
  and persist the event row, then enqueue a background job for the
  state mutation. The HTTP response returns 200 fast.
- **Pricing.** One Stripe Product with two recurring prices: $17/month
  (`STRIPE_PRICE_MONTHLY_ID`) and $170/year (`STRIPE_PRICE_ANNUAL_ID`,
  saves $34/year). The 14-day free trial applies to either price.
- **Stripe Tax always on.** Every Checkout session passes
  `automatic_tax: { enabled: true }`. The Customer Portal is also
  configured with automatic tax. Therapists are US-only in phase one,
  so this means US sales tax handling.
- **Plan changes.** Therapists can self-serve **monthly → annual**
  upgrades through the Stripe Customer Portal (immediate switch with
  default `create_prorations` proration). Self-serve **annual →
  monthly** downgrades are NOT enabled in phase one; an annual
  customer who wants monthly emails support and is handled case by
  case. Reassess once volume justifies a Stripe Subscription Schedule
  flow.
- **Public visibility during dunning.** A `past_due` therapist stays
  public through Stripe's smart-retry window. The profile only goes
  offline when `subscription.status` reaches `unpaid` (Stripe's
  terminal "we gave up" state) or after `customer.subscription.deleted`.
- "First time therapist gets a 14-day free trial" is enforced by the
  app, not by Stripe. The app refuses to create a trialing checkout
  session for any user whose `trial_started_at` is already set, even
  if the trial ended without conversion. They go to a paid checkout
  session instead.

## Non-standard pattern call-outs (need approval before code)

- **`payment_method_collection: "always"` + `subscription_data.trial_period_days: 14`** is the right Checkout shape for "card required to start trial," per the current Stripe docs. The newer "Trial Offer" API does not support Checkout. Calling this out so it does not look like legacy code.
- **App-owned `Trial Started` page** instead of redirecting straight from Stripe to Account Settings. Done because Stripe webhooks may land after the success redirect. This is industry standard, but worth flagging since it adds a route.
- **Idempotency table** (`stripe_events`) instead of a Redis set or in-memory cache. Postgres is already there; one extra table is the simplest reliable option for a solo developer.

## Phase 1 — Foundation: gem, schema, secrets, webhook endpoint stub

### Scope

Wire Stripe into the app at the infrastructure level. No user-visible
behavior. After this phase, a Rails console can create a Stripe
customer, and a signed Stripe test webhook can hit the endpoint and be
recorded.

### Why this phase comes now

Everything else depends on the gem, the columns, the credentials, and
a verified webhook endpoint. Doing this first means later phases only
deal with product behavior, not plumbing.

### Main changes

| Area | Change |
|---|---|
| Gemfile | Add `stripe` gem (current major version). |
| Rails credentials | Add `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_MONTHLY_ID`, `STRIPE_PRICE_ANNUAL_ID`. Use `Rails.application.credentials.fetch(...)` everywhere. |
| `config/initializers/stripe.rb` | `Stripe.api_key = Rails.application.credentials.fetch(:STRIPE_SECRET_KEY)`. Set `Stripe.api_version` to a pinned version so future Stripe API changes do not break us silently. |
| Migration: `users` | Add `stripe_subscription_id` (string, indexed, unique), `trial_started_at` (datetime), `current_period_end` (datetime, used to show "card will be charged on" date), `subscription_status` (string, mirrors Stripe's `subscription.status`: `trialing`, `active`, `past_due`, `canceled`, `incomplete`, `unpaid`, `paused`). |
| Migration: `stripe_events` | New table. `id` (uuid, default `gen_random_uuid()`), `stripe_event_id` (string, unique), `event_type` (string), `payload` (jsonb), `processed_at` (datetime, nullable), `created_at` / `updated_at`. Index on `stripe_event_id` (unique) and on `(processed_at, event_type)`. |
| `app/models/stripe_event.rb` | Plain ActiveRecord model. No callbacks. |
| `config/routes.rb` | `post "stripe/webhooks", to: "stripe/webhooks#create"`. |
| `app/controllers/stripe/webhooks_controller.rb` | `skip_before_action :verify_authenticity_token`. Skip auth concern. Verify signature with `Stripe::Webhook.construct_event(payload, sig_header, secret)`. On signature error, return 400. Insert/upsert a row in `stripe_events`, return 200. Do not yet act on the event. |
| `app/services/stripe_service.rb` | Thin namespaced module with `customer_for(user)` (find or create the Stripe customer, persist `stripe_customer_id`). |
| `_docs/_processes/stripe.md` | New process doc: env, secrets, webhook endpoint, event handling shape, how to test with the Stripe CLI. |
| `_docs/_processes/notifications.md` | Cross-reference the new `stripe.md` and the `:stripe_errors` channel use. |

### Risks or edge cases

- Forgetting to add the webhook secret to production credentials would silently 400 every event. Add a CI / boot check that the keys are fetchable in production.
- `stripe_customer_id` already exists; double-check no other code path writes it.
- `Rails.application.credentials.fetch` raises if the key is missing; that is intentional per CLAUDE.md and surfaces config mistakes loudly.

### Validation

- `bin/rails console` → `Stripe::Customer.create(email: "test@example.com")` succeeds against test keys.
- `stripe trigger checkout.session.completed` from the Stripe CLI hits `/stripe/webhooks`, the row lands in `stripe_events`, signature verification passes, and the response is 200.
- Bad signature returns 400 and does not persist a row.
- Replaying the same event twice creates exactly one `stripe_events` row (unique constraint on `stripe_event_id`).

### Temporary inconsistency

None. Phase 1 is invisible to therapists.

## Phase 2 — Start Your Trial interstitial + post-Create-Account redirect

### Scope

User-visible scaffold for the interstitial. After saving Create
Account, the therapist lands on `/start-trial`. The page renders the
locked-in copy and two actions: "Start my 14-day free trial" (wired
to phase 3) and "Skip for now" (goes to Account Settings).

In this phase the "Start" button is built but routes to a temporary
controller action that flashes "Stripe checkout coming soon" and
sends the therapist back to `/start-trial`. We ship phase 2 without
real Stripe Checkout so the route, copy, and accessibility work get
reviewed independently from the Stripe integration.

### Why this phase comes now

The interstitial copy and the redirect change to `CreateAccountController#create` are independent of Stripe and are the easiest place to introduce regressions in the signup flow. Shipping them in their own phase keeps the diff small and reviewable.

### Main changes

| Area | Change |
|---|---|
| `config/routes.rb` | `get "start-trial", to: "start_trial#show", as: :start_trial`. `post "start-trial/checkout", to: "start_trial#checkout"` (placeholder in this phase, real in phase 3). `post "start-trial/skip", to: "start_trial#skip"`. |
| `app/controllers/start_trial_controller.rb` | New controller. Inherits from the standard authenticated base. `before_action :require_auth`, `before_action :require_profile`. `before_action :redirect_if_already_trialed` (if `current_user.trial_started_at.present?` or `current_user.subscription_status` is `trialing`/`active`, send to Account Settings). `show` renders the interstitial. `checkout` flashes "Coming soon" and redirects back. `skip` just redirects to Account Settings. The `checkout` action accepts a `plan` param (`"monthly"` or `"annual"`, defaults to `"monthly"`) so phase 3 can plug in the real Stripe call. |
| `app/views/start_trial/show.html.erb` | New view, uses the auth layout (same wide card pattern as Create Account). Primary button: "Start my 14-day free trial" (submits with `plan=monthly` by default). Below it, an "or pay annually and save $34" toggle that flips the submitted plan to `annual`. Secondary text link: "Skip for now — I'll start my trial later." Copy block: "2 weeks to get your profile perfect before your card is charged. Your profile goes online as soon as the trial starts." Plain explanation of what happens if they skip ("No card collected, profile stays offline until you start your trial."). The annual toggle uses a `<button type="submit">` form (no JS dependency for the core action) and clearly states "$170/year (save $34)" so the customer sees the trade. |
| `app/controllers/create_account_controller.rb` | Change the success redirect from `/account-settings` to `/start-trial`. |
| Accessibility | Both buttons get focus styles + `cursor-pointer`. The skip path is a `<button>` inside a small form (POST), not an `<a>`, so it cannot be triggered by a GET prefetch. Heading hierarchy and labels at 1rem minimum per design rules. |
| `_docs/business-rules.md` | No change in this phase — the rules already describe the end state. |

### Risks or edge cases

- A therapist who reloads `/start-trial` after starting a trial in another tab should not be allowed to start a second one. The `redirect_if_already_trialed` before_action covers that.
- Admins with incomplete profiles should not be forced through `/start-trial`. The route inherits `require_profile` so they cannot land here without a profile, which matches existing access rules.
- Browser back-button after skip should not let the therapist re-open `/start-trial` and "skip" again silently — but skipping twice is harmless (no state change), so we accept it.

### Validation

- Sign up a brand-new therapist in dev. After Create Account, the URL is `/start-trial` and the copy renders.
- "Skip for now" → lands on `/account-settings`. No DB writes beyond what already happened.
- "Start my 14-day free trial" → flashes "Stripe checkout is coming soon" and re-renders `/start-trial`.
- A therapist who already has `trial_started_at` is redirected away from `/start-trial`.
- Page passes Lighthouse / axe accessibility checks (focus order, contrast, labels).

### Temporary inconsistency

The "Start my 14-day free trial" button is non-functional until phase 3 ships. Documented in the flash message so testers understand.

## Phase 3 — Stripe Checkout + Trial Started landing + happy-path webhook

### Scope

Replace the placeholder "Start" button with a real Stripe Checkout
session, build the `Trial Started` post-checkout landing page, and
process the events that move a therapist into `trialing_member`.

### Why this phase comes now

Phase 1 set up the plumbing; phase 2 set up the UI shell; phase 3 is
the smallest slice that turns the flow into a real funnel. Cancel,
reactivate, dunning, and the pre-charge email come later.

### Main changes

| Area | Change |
|---|---|
| `app/services/stripe_service.rb` | Add `create_checkout_session(user, plan:)`. Resolves `plan` (`"monthly"` or `"annual"`) to the matching `STRIPE_PRICE_*_ID` and rejects anything else. Calls `Stripe::Checkout::Session.create` with: `mode: "subscription"`, `customer: stripe_customer_id_for(user)`, `line_items: [{ price: resolved_price_id, quantity: 1 }]`, `subscription_data: { trial_period_days: 14, metadata: { user_id: user.id, plan: plan } }`, `payment_method_collection: "always"`, `automatic_tax: { enabled: true }`, `customer_update: { address: "auto", name: "auto" }` (required when automatic tax is on), `success_url: trial_started_url(session_id: "{CHECKOUT_SESSION_ID}")`, `cancel_url: start_trial_url`, `client_reference_id: user.id`, `metadata: { user_id: user.id, plan: plan }`. |
| `StartTrialController#checkout` | Replace placeholder. Reads the `plan` param (defaults to `"monthly"`), calls the service, redirects to `session.url` with a 303. Wraps `Stripe::StripeError` in a Discord ping to `:stripe_errors` and shows a flash to the therapist. |
| `config/routes.rb` | `get "trial-started", to: "trial_started#show", as: :trial_started`. |
| `app/controllers/trial_started_controller.rb` | New. Authenticated. Renders the page. **Does not** read URL params to decide membership state. The page just shows "Your trial is being set up. We'll take you to your account in a moment." with a manual "Continue to my account" link. Optional: a small `<meta http-equiv="refresh" content="3;url=/account-settings">` for the auto-redirect. |
| `app/views/trial_started/show.html.erb` | New view. Same auth layout. |
| `app/jobs/process_stripe_event_job.rb` | New. Reads a `stripe_events` row by id, dispatches by `event_type`, updates `processed_at` on success. Idempotent: a re-run is a no-op. Failures get logged + Discord ping to `:stripe_errors`. |
| `Stripe::WebhooksController#create` | After persisting the row, `ProcessStripeEventJob.perform_later(stripe_event.id)`. |
| `app/services/stripe/event_handlers/checkout_session_completed.rb` | Maps `checkout.session.completed`: find user by `client_reference_id`, persist `stripe_customer_id`, `stripe_subscription_id`, `subscription_status`, `trial_started_at`, `trial_ends_at`, `current_period_end`. Sets `membership_status = "trialing_member"`. |
| `app/services/stripe/event_handlers/customer_subscription_updated.rb` | Maps trial → active conversion: when `subscription.status` flips to `active` and `trial_end` is in the past, set `membership_status = "pro_member"`. |
| `app/services/stripe/event_handlers/customer_subscription_created.rb` | No-op in this phase if `checkout.session.completed` already wrote the fields; defensive update only. Ordering of webhook delivery is not guaranteed. |
| `app/views/account_settings/shared/_layout.html.erb` (or the dashboard layout banner area) | Render a `trialing` notification when `current_user.subscription_status == "trialing"`. Shows trial-end date and card-charge date (`current_period_end`). |
| `_docs/_background-jobs/process_stripe_event_job.md` | New per-job doc. |
| `_docs/_processes/stripe.md` | Update with the event types we now handle and the order they may arrive in. |

### Risks or edge cases

- **Webhook arrives before redirect.** `Trial Started` does not depend on it.
- **Redirect arrives before webhook.** The therapist may briefly see Account Settings without the trialing banner. Acceptable; the next page load shows it. Flagged in the trial-started copy ("we'll take you to your account in a moment").
- **Out-of-order events.** `customer.subscription.created` may arrive after `checkout.session.completed`; the handlers are written to be safely repeatable, with `subscription_status` only moving forward through Stripe's defined states.
- **User abandons checkout.** Stripe's `cancel_url` returns them to `/start-trial`. No DB writes have happened (we only write on `checkout.session.completed`). Confirmed safe.
- **Therapist closes the browser mid-trial.** Webhook still lands; state is set; next sign-in shows trialing banner.
- **A second trial attempt by the same user.** App refuses (`redirect_if_already_trialed` from phase 2).
- **Stripe Customer reuse.** `StripeService.customer_for(user)` always passes `customer: stripe_customer_id` if present, so we do not create duplicates.
- **Test mode vs live mode keys mixed up.** Pin keys per environment in credentials and add a boot-time sanity check that the test key is not used in production.

### Validation

- A new therapist clicks "Start my 14-day free trial" → redirected to Stripe Checkout → completes test payment with `4242 4242 4242 4242` → returns to `/trial-started?session_id=...` → continues to Account Settings → sees the trialing banner with the right dates.
- Stripe CLI `stripe listen --forward-to localhost:3000/stripe/webhooks` shows the events landing in `stripe_events` and `processed_at` getting set.
- Replaying the same `checkout.session.completed` event leaves the user in the same state (idempotent).
- Canceling at the Stripe-hosted page (the `cancel_url`) returns to `/start-trial` with no DB changes and the start button still works.
- Banner only shows for `subscription_status == "trialing"`.

### Temporary inconsistency

- For the time the webhook is in flight, the therapist may see Account Settings with the "no active trial" banner before the `trialing` banner appears. Resolved within seconds when the webhook lands. Documented in the trial-started copy.
- Account Settings does NOT yet show the "start your free trial" notification for therapists without a trial — that ships in phase 4. In the gap, a therapist who skipped checkout sees no banner. Acceptable for a few hours / one PR cycle.

## Phase 4 — Account Settings notifications + customer portal

### Scope

Two related, small deliverables:

1. The "start your free trial today" notification at the top of
   Account Settings for therapists with no active trial / paid sub.
2. A "Manage subscription" action in the Membership section that
   creates a Stripe Customer Portal session and redirects the
   therapist to Stripe's hosted portal.

### Why this phase comes now

Banner + portal close the user-facing loop for the common case (the
therapist can self-serve cancel, update card, view invoices). They
depend on phase 3's `subscription_status` field being populated and
on the Stripe customer existing.

### Main changes

| Area | Change |
|---|---|
| Account Settings layout | Add the "start your free trial" banner condition: render when `current_user.subscription_status.blank?` (or specifically `nil`/`"canceled"` with no active trial). Link to `/start-trial`. |
| `app/controllers/account_settings/memberships_controller.rb` | Add `portal` action: creates `Stripe::BillingPortal::Session.create(customer:, return_url: account_settings_membership_url)` and redirects. |
| `app/views/account_settings/memberships/show.html.erb` | Replace the "Subscription management coming soon" placeholder. Show current status, trial end / next charge date, and a "Manage subscription" form button. |
| `config/routes.rb` | `post "account-settings/membership/portal", to: "account_settings/memberships#portal", as: :account_settings_membership_portal`. |
| `_docs/business-rules.md` | No change. |

### Risks or edge cases

- A therapist with no `stripe_customer_id` reaches the portal action — guard with a `redirect_to` to `/start-trial`.
- The Stripe Customer Portal is configured in the Stripe Dashboard. Document the configuration in `_docs/_processes/stripe.md`. Phase-one settings: cancel = on, update payment method = on, view invoices = on, automatic tax = on, **subscription update = on but limited to monthly → annual upgrades only** (configure the portal so the only switchable destination from the monthly price is the annual price; the annual price has no switchable destinations). This sidesteps the annual → monthly refund-expectation question. Annual customers who want monthly email support and are handled case by case in phase one.
- After cancellation in the portal, the user returns to the membership page where `subscription_status` may still be `trialing`/`active` until the webhook lands. Phase 5 covers the cancel webhook.
- Plan switch mid-trial (monthly → annual): Stripe preserves the trial; trial-end stays the same and the first charge at trial end is at the annual price ($170). Verify this in test mode before launch.

### Validation

- A therapist who skipped checkout sees the "start your free trial" banner on Account Settings and the link works.
- A trialing therapist sees the trialing banner (from phase 3) and "Manage subscription" opens the Stripe portal.
- A pro therapist sees the right Membership page with their next charge date.
- Cancelling in the portal eventually reflects in the app (after phase 5).

### Temporary inconsistency

Cancellation in the portal does not yet update `membership_status` until phase 5's `customer.subscription.deleted` handler ships.

## Phase 5 — Cancel + reactivate handling + admin pings

### Scope

Handle `customer.subscription.deleted` (cancel) and the reactivation
case (a previously canceled user buying a paid subscription via the
membership page or Stripe portal). Send the dev-team Discord pings
required by business rules.

### Why this phase comes now

Phase 3 covered the happy path. Phase 4 gave users a way to cancel.
Phase 5 closes the loop: when they cancel, the app correctly demotes
them to `member`, hides their public profile, and pings me.

### Main changes

| Area | Change |
|---|---|
| `app/services/stripe/event_handlers/customer_subscription_deleted.rb` | Set `membership_status = "member"`, `subscription_status = "canceled"`, leave `stripe_customer_id` and `stripe_subscription_id` for audit. Ping `:admin` Discord: "Therapist <id> canceled their subscription." |
| Reactivation path | When a user without an active sub re-opens `/start-trial`, they hit a "subscribe" page (no second free trial — `trial_started_at` is set). The checkout session is created with NO `trial_period_days` so they're charged immediately on success. On `checkout.session.completed`, set `membership_status = "pro_member"` and ping `:admin` "Therapist <id> reactivated their subscription." |
| `StartTrialController#show` | Branch the view on `current_user.trial_started_at.present?` to render the "subscribe" copy instead of "start trial" copy. |
| `app/views/start_trial/show.html.erb` | Add the subscribe-mode partial / branch. |
| `_docs/business-rules.md` | No change. |

### Risks or edge cases

- A canceled user whose card got auto-deleted by Stripe's portal still has a `stripe_customer_id`. Reusing the customer is fine; Stripe will collect a new card during the new checkout session.
- A user who canceled but is still inside the paid period: business rules say they keep access until the period ends. Stripe sets `cancel_at_period_end = true`; the `customer.subscription.deleted` event fires only at the period boundary. Until then `subscription_status` stays `active`. We display "subscription will end on <date>" in the Membership section.
- Admin pings should not block the request. They go through `Notifier.notify` which uses the existing async `NotifierJob`.

### Validation

- Use Stripe CLI to trigger `customer.subscription.deleted`. The user flips to `member`, the public profile drops, and a Discord message lands in `:admin`.
- A canceled therapist who returns to `/start-trial` sees the "subscribe" variant and gets charged on completion (no second free trial). A new `:admin` ping fires.

### Temporary inconsistency

None expected.

## Phase 6 — Pre-charge reminder email

### Scope

Listen for `customer.subscription.trial_will_end` (Stripe sends this
3 days before the trial ends) and send our own reminder email via
ActionMailer / Resend. This is in addition to Stripe's built-in
trial-end email.

### Why this phase comes now

It is the smallest dependency on phases 1–3 that stands alone, and it
is explicit in business rules. Saving it for last keeps the earlier
phases shippable without it.

### Main changes

| Area | Change |
|---|---|
| `app/services/stripe/event_handlers/customer_subscription_trial_will_end.rb` | Looks up the user by subscription id, enqueues `TrialEndingReminderMailer.with(user:).deliver_later`. |
| `app/mailers/trial_ending_reminder_mailer.rb` | New mailer. Subject and body explain: "Your free trial ends on <date>. Your card will be charged $X on that date. To cancel, click here." |
| `app/views/trial_ending_reminder_mailer/notify.html.erb` and `.text.erb` | New templates. |
| `_docs/_processes/email.md` (or wherever transactional email is documented) | Add an entry. |

### Risks or edge cases

- A therapist who cancels before the trial ends but after the `trial_will_end` event has already been processed: the email is on its way; not a problem because Stripe will not actually charge them.
- Test that the email link to "cancel" actually points to the membership page or directly to the customer portal.

### Validation

- `stripe trigger customer.subscription.trial_will_end` enqueues and delivers the email in dev.
- Subject and body render correctly with merged dates.

### Temporary inconsistency

None.

## Phase 7 — Payment failure + dunning

### Scope

Handle `invoice.payment_failed` and the `past_due` /
`unpaid` subscription states gracefully. Show a Membership banner
asking the therapist to update their card. Optionally pause the
public profile after N failed attempts.

### Why this phase comes now

Last because it is the least common path for a brand-new app and the
highest-friction work. Stripe's smart retries cover most cases for
free.

### Main changes

| Area | Change |
|---|---|
| `app/services/stripe/event_handlers/invoice_payment_failed.rb` | Update `subscription_status` from the event payload. Send the user an email with a link to the customer portal. |
| Account Settings banner | Add "Your last payment failed — update your card" banner when `subscription_status == "past_due"`. |
| Public profile gating | `past_due` therapists stay public through the smart-retry window. The profile only goes offline when `subscription.status` becomes `unpaid` (Stripe's terminal "we gave up" state) or after `customer.subscription.deleted`. Implement by treating `past_due` the same as `active` for the public-visibility check; treat `unpaid` and `canceled` as not-public. |
| `_docs/business-rules.md` | Add an explicit rule for the dunning case. |

### Risks or edge cases

- A therapist with a temporarily-declined card recovers automatically; we do not want to nuke their public profile every time their bank flags a $29 charge for review.
- Make sure the banner is dismissable for the day but reappears the next page load — they shouldn't be able to ignore it forever.

### Validation

- `stripe trigger invoice.payment_failed` flips the user to `past_due`, the banner shows, the email goes out.
- Stripe's smart retry succeeds → `invoice.payment_succeeded` flips back to `active` → banner disappears.

### Temporary inconsistency

None.

## Risks (overall)

- **Webhook downtime.** If our endpoint is down for hours, Stripe retries for 3 days (live) but state will be stale. Better Stack already alerts on 5xx; we should add a Better Stack monitor specifically for the `/stripe/webhooks` endpoint.
- **Secrets in the wrong env.** Use Rails credentials (`fetch`) so missing keys raise loudly. Add a boot-time check that the live key is not present in development.
- **Dual emails.** Stripe sends pre-charge emails and we also send one. Make sure our copy does not contradict Stripe's wording. Coordinate the timing so both emails do not arrive in the same minute.
- **Free trial abuse.** Same email cannot trial twice (we gate on `trial_started_at`), but a determined user can sign up with a new email. Acceptable risk for phase one.
- **Stripe API version drift.** Pin `Stripe.api_version` in the initializer so a Stripe-side default version bump does not change behavior silently.
- **Profile goes online during trial → therapist abandons during trial → public profile is live for someone who never paid.** Business rules say `trialing_member` is public; this is intentional. After cancel or trial expiry without conversion, `customer.subscription.deleted` flips them to `member` and the profile drops.
- **Idempotency window.** `stripe_events.stripe_event_id` unique constraint prevents re-processing across the whole table forever. We never delete event rows in phase one. Reassess after a year if the table grows large.
- **PII in `payload` jsonb.** Stripe events contain customer email and partial card info. Treat the column as sensitive: do not log it, do not surface it in Avo without redaction.

## Resolved decisions (2026-04-30)

These were open questions in the first draft. Recorded here for the
implementer:

1. **Price.** $17/month, $170/year (saves $34). Two prices on one
   Product. `Start Your Trial` defaults to monthly with an annual
   toggle.
2. **`past_due` visibility.** Stay public through Stripe's smart
   retries; drop only on `unpaid` or `customer.subscription.deleted`.
3. **Stripe Tax.** Always on. `automatic_tax: { enabled: true }` on
   every Checkout session and in the Customer Portal config.
4. **Customer Portal plan switching.** Monthly → annual upgrade only,
   self-serve via the portal with default proration. Annual → monthly
   downgrades go through email support in phase one (avoids the
   refund-expectation problem). Reassess later if volume justifies a
   Subscription Schedule flow.
