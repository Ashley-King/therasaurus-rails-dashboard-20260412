# Changelog

## 2026-05-02

### Added
- **Plan change scheduled email + business rule.** When a therapist
  schedules a plan change in the Stripe Customer Portal (monthly ↔
  yearly), Stripe queues the change to the end of the current billing
  period and fires `subscription_schedule.created`. New
  [`PlanChangeScheduledMailer`](app/mailers/plan_change_scheduled_mailer.rb)
  sends the therapist a confirmation with the effective date and the
  new amount (Stripe doesn't send a scheduled-change email by
  default). Wired in
  [`config/initializers/billing_subscribers.rb`](config/initializers/billing_subscribers.rb).
  New "Plan change rules" section in
  [`business-rules.md`](_docs/business-rules.md) codifies: portal is
  the single surface for plan changes, all changes apply at
  end-of-period (no proration, no refunds), the app sends a scheduled
  email, no separate email at apply-time (the next Stripe receipt
  carries the new amount).

### Changed
- **Customer Portal phase-one config corrected.** Earlier docs claimed
  the portal could enforce "monthly → yearly upgrades only" via
  per-source-price restrictions. That feature does not exist in
  Stripe; the `subscription_update.products[].prices` array is a flat
  list of allowed destinations with no source filtering. Updated
  [`_docs/_processes/stripe.md`](_docs/_processes/stripe.md) to
  describe the actual phase-one config: subscription update on, both
  prices listed, proration `none`, downgrades wait until end of
  billing period (so a yearly customer's downgrade queues to renewal
  and never triggers a refund).
- **Renamed `STRIPE_PRICE_ANNUAL_ID` → `STRIPE_PRICE_YEARLY_ID`** to
  match the credential names actually set in dev. Added
  `STRIPE_PRODUCT_MONTHLY_ID` and `STRIPE_PRODUCT_YEARLY_ID` to
  `credentials.example` for reference (the app does not read them —
  Pay/Stripe associate prices with products automatically). Internal
  `plan` param in `StartTrialController` and the start-trial form
  buttons rename `"annual"` → `"yearly"` to match. User-facing copy
  ("annually", "$170/year") is unchanged. Production boot guard in
  `config/initializers/stripe.rb` now checks for `STRIPE_PRICE_YEARLY_ID`.
- **Trial flow rewired on top of the Pay gem.** Replaced the
  hand-rolled Stripe integration (built 2026-04-30) with
  [`pay` ~> 11.6](https://github.com/pay-rails/pay) so we offload
  webhook idempotency, customer/subscription/charge persistence, and
  pre-charge / dunning mailers to a maintained library. The user-facing
  flow (Start Your Trial → Stripe Checkout → Trial Started → Account
  Settings → portal → cancel + reactivate) is unchanged.
  - **Schema.** Dropped `stripe_events` and the
    `stripe_customer_id`, `stripe_subscription_id`, `subscription_status`,
    `trial_started_at`, `trial_ends_at`, `current_period_end` columns
    from `users` (all migrated to `pay_customers` / `pay_subscriptions`,
    with UUID-compatible polymorphic owner refs since the app default
    `primary_key_type` is `:uuid`). Kept `users.membership_status` as
    the app-side denorm.
  - **Single writer for `users.membership_status`.** New
    [`BillingSync`](app/services/billing_sync.rb) maps Stripe's
    subscription status to one of `trialing_member` / `pro_member` /
    `member` and is the only code that writes the column.
    `past_due` stays `pro_member` (and therefore public) through
    Stripe's smart-retry window per business rules.
  - **App-side webhook subscribers** registered via
    `Pay::Webhooks.delegator.subscribe` in
    [`config/initializers/billing_subscribers.rb`](config/initializers/billing_subscribers.rb)
    handle our three custom reactions: `BillingSync` re-sync, `:admin`
    Discord ping on cancel, `:admin` Discord ping on reactivation
    (detected via `subscription.metadata.reactivation = "true"`).
    Subscriber exceptions ping `:stripe_errors` and re-raise.
  - **Controllers.** `StartTrialController#checkout` now calls
    `current_user.payment_processor.checkout(...)`. Reactivation is
    detected via `current_user.pay_subscriptions.exists?` (no second
    free trial). `AccountSettings::MembershipsController#portal` calls
    `current_user.payment_processor.billing_portal(return_url:)`.
  - **Webhook endpoint** moved from our hand-rolled
    `POST /stripe/webhooks` to Pay's auto-mounted
    `POST /pay/webhooks/stripe`.
  - **Mailers.** Replaced `TrialEndingReminderMailer` and
    `PaymentFailedMailer` with overridden Pay templates at
    `app/views/pay/user_mailer/{subscription_trial_will_end,payment_failed}.{html,text}.erb`.
    Pay sends both via `deliver_later`. Receipt + refund mailers
    disabled (Stripe sends its own).
  - **Deleted:** `StripeService`, `Stripe::WebhooksController`,
    `ProcessStripeEventJob`, `StripeEvent` model, the entire
    `app/services/stripe/event_handlers/` tree, `TrialEndingReminderMailer`,
    `PaymentFailedMailer`, and the per-job doc.
  - **Docs.** Rewrote
    [`_docs/_processes/stripe.md`](_docs/_processes/stripe.md);
    removed the `ProcessStripeEventJob` entry from
    [`_docs/background-jobs.md`](_docs/background-jobs.md).

## 2026-04-30

### Changed
- **Cap services and areas of expertise at 20 each.** Therapists can
  now select up to 20 services and up to 20 areas of expertise (of
  which up to 5 may still be starred as focused specialties). Caps are
  enforced server-side via `MAX_SERVICES` in
  [`YourPractice::ServicesController`](app/controllers/your_practice/services_controller.rb)
  and `MAX_SPECIALTIES` in
  [`YourPractice::SpecialtiesController`](app/controllers/your_practice/specialties_controller.rb)
  using a defensive `.first(N)` truncation, mirroring the existing
  `MAX_FOCUS = 5` pattern. The Stimulus pickers
  ([`services_picker_controller.js`](app/javascript/controllers/services_picker_controller.js),
  [`specialties_picker_controller.js`](app/javascript/controllers/specialties_picker_controller.js))
  disable unchecked rows once the cap is reached. No DB constraint is
  added — Postgres CHECK can't count sibling rows, and a trigger would
  conflict with the project's "prefer Rails over DB functions and
  triggers" rule.

### Added
- **Payment failure + dunning (phase 7 of trial flow).** New
  [`Stripe::EventHandlers::InvoicePaymentFailed`](app/services/stripe/event_handlers/invoice_payment_failed.rb)
  enqueues
  [`PaymentFailedMailer.notify`](app/mailers/payment_failed_mailer.rb)
  with the failed amount and Stripe's next retry timestamp; the handler
  deliberately does not touch `membership_status` (per business rules a
  `past_due` therapist stays public through Stripe's smart-retry
  window). Account Settings shared layout shows a "Your last payment
  failed" warning banner for `subscription_status == "past_due"`. New
  Dunning rules section in
  [`business-rules.md`](_docs/business-rules.md) codifies the
  `past_due` → `unpaid` / `canceled` public-visibility transition.
- **Pre-charge reminder email (phase 6 of trial flow).** New
  [`Stripe::EventHandlers::CustomerSubscriptionTrialWillEnd`](app/services/stripe/event_handlers/customer_subscription_trial_will_end.rb)
  fires 3 days before the trial ends and enqueues
  [`TrialEndingReminderMailer.notify`](app/mailers/trial_ending_reminder_mailer.rb)
  with the trial-end date, charge date, and a derived price label
  (e.g. "$17/month") via `deliver_later`. HTML and text templates
  ship together. ApplicationMailer default `from` updated to the
  TheraSaurus address.
- **Cancel + reactivate handling, admin pings (phase 5 of trial flow).**
  New
  [`Stripe::EventHandlers::CustomerSubscriptionDeleted`](app/services/stripe/event_handlers/customer_subscription_deleted.rb)
  demotes the user to `member`, sets `subscription_status = "canceled"`
  (keeps the Stripe ids for audit), and pings `:admin` on Discord.
  Wired into
  [`ProcessStripeEventJob`](app/jobs/process_stripe_event_job.rb).
  Reactivation path: a returning therapist whose
  `trial_started_at` is set sees a "subscribe" variant of `/start-trial`
  (no second free trial); their checkout session is created without
  `trial_period_days` and carries `metadata.reactivation = "true"`. On
  `checkout.session.completed`, the handler pings `:admin` so we know
  the user came back. `StartTrialController#redirect_if_currently_subscribed`
  now lets cancelled-then-returning users through (only bounces
  trialing/active/past_due states).
- **Account Settings notifications + Customer Portal (phase 4 of trial
  flow).** Account Settings shared layout now also shows a "start your
  free trial today" warning banner for therapists with no active trial
  or paid sub (`subscription_status` blank or `canceled`). Membership
  section
  ([`AccountSettings::MembershipsController`](app/controllers/account_settings/memberships_controller.rb))
  replaces the placeholder copy with status, trial-end / next-charge
  date, and a "Manage subscription" button that posts to the new
  `POST /account-settings/membership/portal` route to mint a
  `Stripe::BillingPortal::Session` and redirect. Therapists without a
  `stripe_customer_id` see a "Start your 14-day free trial" CTA
  instead. Portal failures ping `:stripe_errors` on Discord.
- **Stripe Checkout + Trial Started landing + happy-path webhooks
  (phase 3 of trial flow).**
  [`StripeService.create_checkout_session`](app/services/stripe_service.rb)
  builds a `mode: "subscription"` Checkout session with
  `payment_method_collection: "always"`,
  `subscription_data.trial_period_days: 14`,
  `automatic_tax: { enabled: true }`, `customer_update` set to `auto`
  for both name and address (required when automatic tax is on),
  monthly or annual price, and `client_reference_id` plus
  `metadata.user_id` on both the session and the subscription so
  out-of-order webhook deliveries can still find the user. Real
  checkout is wired in
  [`StartTrialController#checkout`](app/controllers/start_trial_controller.rb);
  Stripe errors get a `:stripe_errors` Discord ping and a graceful
  re-render of `/start-trial`.
  New `GET /trial-started` route +
  [`TrialStartedController`](app/controllers/trial_started_controller.rb)
  +
  [view](app/views/trial_started/show.html.erb) — the page does NOT
  read `session_id` to decide membership state and tolerates the
  webhook landing after the redirect (3-second meta refresh +
  manual continue link to Account Settings).
  New
  [`ProcessStripeEventJob`](app/jobs/process_stripe_event_job.rb)
  dispatches `stripe_events` rows to the matching
  [`Stripe::EventHandlers::*`](app/services/stripe/event_handlers)
  handler and stamps `processed_at`. Phase 3 ships handlers for
  `checkout.session.completed`, `customer.subscription.created`, and
  `customer.subscription.updated`. Trial → active flips
  `membership_status` from `trialing_member` to `pro_member`. The
  webhook controller now enqueues the job after persisting each row.
  Account Settings shared layout shows a "You're on a free trial"
  notification for `subscription_status == "trialing"` users with
  trial-end and card-charge dates.
  New per-job doc
  [`process_stripe_event_job.md`](_docs/_background-jobs/process_stripe_event_job.md)
  and updated [`stripe.md`](_docs/_processes/stripe.md).
- **Start Your Trial interstitial (phase 2 of trial flow).** New
  `GET /start-trial` route renders the post-signup interstitial copy
  with a primary "Start my 14-day free trial — $17/month" submit
  button, an outline "Or pay annually and save $34 — $170/year" submit
  button (both posting `plan` to `POST /start-trial/checkout`), and a
  "Skip for now" text-link button posting to
  `POST /start-trial/skip` (POST so a GET prefetch can't trigger
  skip). `CreateAccountController#create` now redirects to
  `/start-trial` instead of `/account-settings`.
  [`StartTrialController`](app/controllers/start_trial_controller.rb)
  bounces users with `trial_started_at` set or with
  `subscription_status` of `trialing`/`active` to Account Settings.
  The checkout action is a placeholder until phase 3 wires real
  Stripe Checkout.
- **Stripe foundation (phase 1 of trial flow).** Added the `stripe`
  gem, pinned `Stripe.api_version = "2026-04-22.dahlia"` in
  `config/initializers/stripe.rb`, with a boot-time guard that fails
  in production if any Stripe credential is missing and refuses to
  start in development if the secret key is a `sk_live_…` key. New
  schema: `users.stripe_subscription_id` (unique), `trial_started_at`,
  `current_period_end`, `subscription_status`; new `stripe_events`
  table (uuid pk, unique `stripe_event_id`, `event_type`, jsonb
  `payload`, `processed_at`) backing webhook idempotency. New
  `POST /stripe/webhooks` endpoint
  ([`Stripe::WebhooksController`](app/controllers/stripe/webhooks_controller.rb))
  verifies the signature, persists the raw event, returns 200 fast,
  and treats `RecordNotUnique` re-deliveries as success. Added
  [`StripeService.customer_for(user)`](app/services/stripe_service.rb)
  for find-or-create of the Stripe Customer. Renamed the
  `STRIPE_PRICE_ID`/`STRIPE_PRODUCT_ID` example credentials to
  `STRIPE_PRICE_MONTHLY_ID` / `STRIPE_PRICE_ANNUAL_ID`. New
  [`_docs/_processes/stripe.md`](_docs/_processes/stripe.md).

### Changed
- **Business rules: post-signup trial flow.** Updated
  `_docs/business-rules.md` to reflect the new funnel. After Create
  Account, the therapist hits a `Start Your Trial` interstitial that
  offers Stripe checkout (14-day trial, card on file, profile goes
  public immediately) or a skip to Account Settings (no card, profile
  not public, persistent "start your free trial" notification).
  Trial length changed from 30 days to 14 days. Added rules for
  pre-charge reminder email from the app, internal admin notifications
  on cancel and reactivate, and "no card on file" state for therapists
  who skipped checkout. Code and copy changes to follow.
- **Plan: Stripe trial + checkout flow.** Added
  `_docs/_plans/stripe-trial-flow.md`, a 7-phase implementation plan
  for the post-signup billing funnel: foundation (gem, schema,
  webhook), Start Your Trial interstitial, Stripe Checkout + Trial
  Started landing + happy-path webhooks, Account Settings
  notifications + customer portal, cancel/reactivate + admin pings,
  pre-charge reminder email, payment failure / dunning. Calls out
  three non-standard patterns up front (Checkout `trial_period_days`
  shape, app-owned post-checkout landing page, Postgres-backed
  webhook idempotency). Resolved decisions: $17/mo + $170/yr two
  prices on one Product, Stripe Tax always on, public profile stays
  through smart retries (drops on `unpaid` / `deleted`), Customer
  Portal allows monthly → annual upgrades only (annual → monthly
  goes through email support in phase one).
- **Business rules: post-checkout landing page (Section 6a).** Added
  rules for an app-owned `Trial Started` landing page that Stripe's
  `success_url` points to. The landing page renders correctly even if
  the webhook has not been processed yet (Stripe waits up to 10s
  before redirecting, per Stripe Checkout fulfillment docs), does not
  set membership state from URL parameters, and forwards the therapist
  to Account Settings where the `trialing` notification appears once
  the webhook lands. `cancel_url` sends them back to
  `Start Your Trial`. Sharpened the `Start Your Trial` value prop copy
  to "2 weeks to get your profile perfect before your card is charged.
  Your profile goes online as soon as the trial starts."

## 2026-04-26

### Changed
- **Your Practice: "New clients" section moved from Clients to top of
  Availability.** The accepting / waitlist / free intro call fieldset
  now lives at the top of the Availability form, and its three
  attributes (`accepting_new_clients`, `has_waitlist`,
  `free_phone_call`) moved from `clients_params` to
  `availability_params`. The model-level validation (waitlist + accepting
  cannot both be true) is unchanged and now surfaces on the Availability
  page.

### Added
- **Ransack search backend for Avo.** Added the `ransack` gem (Avo's
  documented search/filter backend) and a `Ransackable` concern included
  in `ApplicationRecord` that allowlists every column and association for
  Ransack 4. Fixes `undefined method 'ransack' for class Service` in the
  Avo admin search. If a sensitive column is added to any model in the
  future, override `ransackable_attributes` on that one model to exclude it.

### Fixed
- **Your Practice → Specialties and Services: Save button placement.**
  Restructured both pages so `<section class="ts-card">` wraps the form
  (matching accessibility/introductions/etc.). The Save button now sits
  inside the card with a top divider instead of floating below it on the
  page background, and gains the `cursor-pointer` class.

## 2026-04-25

### Added
- **Your Practice → Availability: Business hours.** Therapists can set
  weekly business hours from the Availability page. Each day has an
  "Open / Closed" toggle and 15-minute open / close-time dropdowns.
  Per-row "Copy down" replicates a day's hours into every day below it,
  and a single "Clear all hours" button marks every day closed. A new
  US time-zone select labels the hours. The Availability sidebar entry
  also moved above Introduction. The page replaces all `business_hours`
  rows for the therapist on save inside a transaction; absence of a row
  for a day means "closed" — no separate column needed. Backed by the
  existing `business_hours` table and a new `therapists.time_zone`
  column (validated against `ActiveSupport::TimeZone.us_zones`).

### Changed
- **About You → Professional identity: identity-field visibility controls.**
  Birth date moved to the top of the section with reworded helper text
  clarifying it is voluntary, used only for matching against parent
  age-range searches, and never shown on the profile. Pronouns, gender
  identity, and race / ethnicity each gained an "I'm comfortable showing
  this on my profile" checkbox (unchecked by default) backed by new
  `therapists.show_pronouns_on_profile`, `show_genders_on_profile`, and
  `show_race_ethnicities_on_profile` boolean columns. Selections are still
  used for search matching when the box is unchecked; only profile display
  is gated.

### Docs
- **Documentation sweep to match current app state.** Several docs had
  drifted since the dashboard was removed and Account Settings became
  the post-signin landing page (CHANGELOG 2026-04-17), since
  Services/Specialties were split into separate pages with the new
  picker UX (CHANGELOG 2026-04-23), and since Turnstile was dropped
  from the auth views.
  - `_docs/turnstile.md` rewritten to state Turnstile is **not
    currently wired**; preserves the rebuild checklist in case it
    comes back. References to `SessionsController` /
    `app/views/sessions/` (which don't exist) removed.
  - `_docs/_processes/auth.md` updated: post-signin redirect targets
    `/account-settings`, not `/dashboard`. `require_profile` no
    longer claims to be used by `DashboardController` (removed).
    Turnstile section now points at the rewritten doc.
  - `_docs/business-rules.md` updated: "Dashboard home rules"
    section replaced with "Signed-in landing page rules" describing
    Account Settings. "Support request rules" section replaced with
    "Feature requests" describing the actual built feature. Profile
    editor rules now describe the page-per-form pattern (no modals)
    and list the real `About You` / `Your Practice` /
    `Account Settings` sidebar entries. Practice details, fees,
    services, specialties, and availability sections updated to
    match the current Trix toolbar, write-in-via-feature-request
    flow, insurance combobox, telehealth platforms, and split pages.
  - `_docs/_processes/admin-panel.md` updated: resources list now
    includes `FeatureRequest`, `TelehealthPlatform`,
    `ServiceToCategory`, `SpecialtyToCategory`. Redirect target for
    non-admins corrected from `/dashboard` to `/account-settings`.
    New "Admin tools" section documents
    `/admin-tools/credentials/:id/document`.
  - `_docs/_processes/rate-limiting.md` updated: added
    `zip-search/ip` Rack::Attack throttle to the table; added
    `AccountSettings::UpdateEmailsController` Rails-layer limits
    (the email change flow that was previously a TODO is now
    implemented and rate-limited); added `auth.rate_limit.email_change`
    log event; added `feature-requests` to the
    intentionally-not-rate-limited list.
  - `_docs/_processes/notifications.md` updated: added "Feature
    request submitted" to the Currently wired section with the kind
    → channel routing map.
  - `_docs/index.md` now lists `admin-panel.md` and updates the
    Turnstile description.

### Added
- **Therapist birth date.** New `birth_date` (date) column on `therapists`,
  edited from About You → Identity via Rails' three-dropdown `date_select`
  (Month / Day / Year, year range 1940..current). Field is optional. Helper
  text on the form makes clear the value is never displayed publicly and is
  only used internally to match therapists to age-range searches. Validated
  in `Therapist#birth_date_within_range` (year in `BIRTH_YEAR_RANGE`, not in
  the future) and permitted as multiparameter date params in
  `AboutYou::ProfessionalIdentitiesController`.
- **Profile FAQs.** Therapists can add up to 5 question/answer pairs
  on the Your Practice → FAQs page. Stored in a new `therapist_faqs`
  table (uuid PK, `therapist_id` FK with `on_delete: :cascade`,
  `question` varchar(200), `answer` text, timestamps). Question
  capped at 200 chars, answer at 1000 chars. HTML tags in either
  field are stripped server-side via `strip_tags` before validation;
  the public profile renders values escaped, so the stored data
  stays plain text. The form uses `accepts_nested_attributes_for`
  with `reject_if: :all_blank` and `allow_destroy: true`; the
  `faqs` Stimulus controller hides the "Add a question" button at
  5 rows, and the Remove button toggles `_destroy=1` on persisted
  rows or strips the row outright on unsaved ones. Max-5 is
  enforced by a model validation on `Therapist` so the cap holds
  even if the JS is bypassed.
- **Feature request modal, drop-in anywhere.** New
  `shared/feature_request_link` partial renders a text link plus a
  native `<dialog>` modal scoped by `kind:` —
  `specialty`, `service`, `insurance_company`, `college`, or
  `general`. Each kind has its own default link text, modal title,
  lead, and placeholder copy in `FeatureRequestHelper`. Multiple
  links can live on the same page (e.g. footer "Feature request" plus
  page-level "Don't see your specialty?"); each instance gets a
  unique dialog + Turbo Frame ID. Wired into the dashboard footer
  (general), specialties page (specialty), and services page
  (service).
- **`feature_requests` table + model.** Stores
  `therapist_id`, `kind`, `body`, `page_url`, `status`
  (default `open`). Submissions go through
  `FeatureRequestsController#create`, which routes the Discord ping
  to the kind-specific channel
  (`:specialties`, `:services`, `:insurance_write_in`,
  `:college_write_in`, otherwise `:feature_requests`) via the
  existing `Notifier`. Admin viewing/triage lives in Avo at
  `/admin/resources/feature_requests`.
- **`feature-request` Stimulus controller.** Wraps the native
  `<dialog>` element for free focus trap, ESC dismissal, and inert
  background. Backdrop click closes; Cancel and ✕ buttons close.

## 2026-04-23

### Changed
- **Specialties gets its own page with focus-star selection.** Mirrors
  the services filter/search picker and adds a star toggle on each
  selected chip to mark it as a "focus specialty" (max 5). Focus
  chips sort first and render with a gold border and filled star;
  the remaining selected specialties are "other areas of expertise."
  When 5 are starred, the remaining stars grey out with a helper
  message. Server-side `YourPractice::SpecialtiesController#update`
  caps focus at 5, syncs `practice_specialties.is_focus`, and wraps
  the sync in a transaction. Removed the now-obsolete
  `services_specialties` combined controller/view/route.

- **Services split off into its own page with a filter/search picker.**
  `Services & Specialties` becomes two sidebar entries: `Services`
  (`/your-practice/services`, now fully functional) and `Specialties`
  (`/your-practice/specialties`, still the placeholder — dedicated
  page comes next). The services picker handles the many-to-many
  category model without duplicating rows: selected-chips area at top,
  category filter-chip bar (multi-select OR), text search, and a flat
  list of all 149 services with their categories shown as small
  labels. Client-side filtering in the new `services_picker` Stimulus
  controller; server-side `YourPractice::ServicesController#update`
  assigns `therapist.service_ids` in one shot.

- **Fees & Payments is now editable.** The `/your-practice/fees-payment`
  page was a display-only card layout with dead "Edit" links. Replaced
  it with a single form matching the one-page-one-form pattern used
  elsewhere in `Your Practice`: session fees (evaluation, therapy,
  group therapy, consultation, late cancellation), payment-method
  checkboxes, insurance-company combobox (see below), fee notes, and
  cancellation policy (wired to the existing
  `appointment_cancellation_policy` column, which the show view had
  been ignoring). Route gained `:update`;
  `YourPractice::FeesPaymentsController` gained an `update` action.

- **Insurance is now a multi-select autocomplete with pending
  write-ins.** Mirrors the college-autocomplete pattern used for
  education. Therapists search, pick from approved companies, or
  submit a new one — which is stored on `insurance_companies` with
  `status = "pending"` and `submitted_by_therapist_id = therapist.id`.
  The therapist can see their own pending submissions in their search
  results (via `InsuranceCompany.visible_to`) until an admin approves
  or rejects them. Adds a new search endpoint at
  `/your-practice/insurance-companies/search` and a new
  `insurance_combobox` Stimulus controller.

- **Clients & Availability split into two sections.** The single
  `/your-practice/clients-availability` show page (display-only with
  dead "Edit" links) is replaced by two edit pages with forms, matching
  the one-page-one-form pattern used elsewhere in `Your Practice`.
  - `/your-practice/clients` — `accepting_new_clients`, `has_waitlist`
    (mutually exclusive, preserved from the existing model validation),
    `free_phone_call`, plus age-group / language / faith checkbox
    multi-selects.
  - `/your-practice/availability` — in-person / virtual toggles,
    session-format checkboxes, extended availability (early morning,
    evening, weekend), availability notes, and telehealth platforms.
    The telehealth section only reveals when "Virtual therapy" is
    checked (via the new `toggle-visibility` Stimulus controller).
  Sidebar and mobile nav now show "Clients" and "Availability" as
  separate entries.

- **Telehealth platforms are now a many-to-many.** Replaces the unused
  `therapists.telehealth_platform` string column with a
  `telehealth_platforms` table + `practice_telehealth_platforms` join,
  seeded with the six common pediatric-therapy platforms (Zoom for
  Healthcare, Doxy.me, SimplePractice, TheraPlatform, Google Meet,
  Presence). A new `telehealth_platform_other` string on `therapists`
  captures freeform additions (comma-separated). Admin-curated via a
  new Avo resource. Migration: `20260423221610_create_telehealth_platforms`.

- **Session format: added "Parent-child".** Pediatric-relevant fourth
  option alongside Individual / Group / Family, seeded directly into
  `session_formats`.

- **Introduction: 1,500-character cap.** `Therapist` now validates
  `practice_description` against `PRACTICE_DESCRIPTION_MAX = 1500`,
  measuring visible text length (HTML tags stripped via
  `ActionView::Base.full_sanitizer`) so tag overhead doesn't eat into
  the user's budget. The Trix editor shows a live `count / 1500`
  counter (red once over the cap), and the form displays the
  per-field validation error inline if a submission slips past the
  client-side count.

- **Your Practice → Introduction is now a rich-text editor.** The
  read-only preview + "Edit" / "Add" toggle on
  `/your-practice/introduction` is replaced with an always-visible
  Trix editor that writes to `therapists.practice_description`
  (column is `character varying` with no length limit, effectively
  `text` in Postgres — no migration required). A custom
  `<trix-toolbar>` exposes only bold, bulleted list, numbered list,
  undo, and redo — no headings, italic, underline, links, quotes,
  attach. The `rich-text-editor` Stimulus controller imports Trix,
  blocks `trix-file-accept` (ActiveStorage is not installed), and
  bubbles `trix-change` as an `input` event so `form-guard` still
  catches unsaved changes. `IntroductionsController#update`
  sanitizes the submitted HTML to `%w[div br strong ul ol li]` before
  save so anything pasted in (links, headings, scripts) is stripped
  at the boundary. Trix JS + CSS are vendored under
  `vendor/javascript/trix.js` and
  `vendor/assets/stylesheets/trix.css`; pinned via importmap; the
  stylesheet is loaded from the `dashboard` layout.

## 2026-04-21

### Changed
- **Create-account form uses the ZIP combobox (phase 4 of the locations
  + targeted ZIPs plan).** The standalone City / State-select / ZIP
  trio on `/create-account` is replaced with the shared
  `_zip_combobox` partial under `params[:location]`. Picking a
  suggestion fills lat/lng and the `Location` model trusts them
  (sync `geocode_status = "ok"`, no background job). Manual entry
  still falls through `ZipLookup.geocode_with_fallback` on save; only
  an unresolved ZIP flips the record to `pending` and enqueues
  `GeocodeLocationJob` via the `Geocodable` `after_commit`. The
  dashboard layout now shows a blue info banner — "Finalizing your
  location / Your profile will appear in search results within a few
  minutes" — whenever `current_therapist.primary_location.geocode_status
  == "pending"`, so the <1% of signups that land in pending state
  know why they aren't searchable yet.

- **ZIP combobox: three-state UX (empty / selected / manual).** The
  partial now shows just the ZIP finder and a "Can't find your ZIP?
  Enter it manually." checkbox on first render. Picking a suggestion
  replaces the finder with a chip (`02138 — Cambridge, MA ×`) and
  hides the checkbox. Checking the box **replaces the finder entirely**
  with a stacked `City → State → ZIP` trio (all required; state is a
  `<select>`) — autocomplete is off, lat/lng
  are cleared, and the server falls back to
  `ZipLookup.geocode_with_fallback`. State is a `<select>` populated
  from `us_state_codes` (new `ApplicationHelper` memo), city placeholder
  is "San Francisco". The form always submits exactly one `[zip]` value:
  the partial renders two inputs with the same name (one in the finder,
  one in the manual section) and the Stimulus controller toggles
  `disabled` on them so only the mode-appropriate one is part of the
  form. City/state are toggled `required` only while the manual section
  is actually visible (browsers don't gracefully validate
  hidden-but-required fields). A submit-time guard blocks the "typed a
  ZIP but didn't pick and didn't enable manual" case with an inline hint.

### Added
- **Your Practice → Targeted ZIPs: new page (phase 3 of the locations
  + targeted ZIPs plan).** Therapists can save up to 5 `(zip, city,
  state)` tuples they want to appear in search results for, even
  without a physical office there. New table
  `therapist_targeted_zips` (migration
  `20260421000001_create_therapist_targeted_zips`), new model
  `TherapistTargetedZip` with a `within_therapist_cap` validation
  enforcing `MAX_PER_THERAPIST = 5` and a unique index on
  `(therapist_id, zip)`. New controller
  `YourPractice::TargetedZipsController` with `index`, `create`, and
  `destroy`. New sibling job `GeocodeTargetedZipJob` mirrors
  `GeocodeLocationJob` as the async fallback. The `before_save` +
  `after_commit` geocoding pattern is extracted from `Location` into
  a new `Geocodable` concern that both models include — `Location`
  keeps setting `canonical_city`/`canonical_state` (guarded by
  `has_attribute?`) while `TherapistTargetedZip` doesn't have those
  columns. Sidebar + mobile nav both show the new "Targeted ZIPs"
  entry directly below "Locations". Route: `/your-practice/targeted-zips`.

- **Your Practice → Locations: editable primary + additional (phase 2
  of the locations + targeted ZIPs plan).** The read-only placeholder
  is replaced with two cards:
  - **Primary location** (always present, required): street address,
    optional line 2, ZIP autocomplete combobox (fills city/state/lat/lng
    on pick), and "show street address on profile" checkbox.
  - **Additional location** (optional, up to 1): same fields, hidden
    behind an "Add additional location" button when none exists; has
    its own Save and a "Remove additional location" submit that
    destroys the record via a `_destroy=1` flag with `formnovalidate`.
  Saves hit `PATCH /your-practice/locations`. `LocationsController#update`
  reads `locations[primary][...]` or `locations[additional][...]` and
  delegates geocoding to a `before_save` callback on `Location` — if
  lat/lng came from the combobox they're trusted; otherwise
  `ZipLookup.geocode_with_fallback` runs inline. Only when the sync
  path returns nothing does the model set `geocode_status = "pending"`
  and its `after_commit` callback enqueues `GeocodeLocationJob`. The
  redundant `GeocodeLocationJob.perform_later` call in
  `CreateAccountController#create` is removed — the model callback
  covers it now.
  Also renames the `location_type` enum value `alternate` → `additional`
  to match the UI copy (migration
  `20260421000000_rename_location_type_alternate_to_additional`; one
  existing row is `primary`, so the rename has no data impact). New
  Stimulus controller `additional-location` handles the Add toggle.

- **ZIP autocomplete shared infrastructure (phase 1 of the locations +
  targeted ZIPs plan).** New `GET /zip-search` JSON endpoint
  (`ZipLookupsController#search`) returns up to 10 `(zip, city, state,
  lat, lng)` suggestions from `zip_lookups`, deduped on
  `(zip, city, state_id)` and limited to 5-digit numeric prefixes ≥ 2
  chars. Results include `city_alt` values as separate options so
  therapists searching under a common name (e.g. `Ventura` for
  `San Buenaventura`, `Saint Lucie` for `Port Saint Lucie`) can
  still find their ZIP. Query logic lives on
  `ZipLookup.prefix_search`. Requires auth (no `require_profile`, so `/create-account` can
  use it). Rate-limited at 30 req/min per IP via Rack::Attack. New
  `zip-combobox` Stimulus controller and
  `app/views/shared/_zip_combobox.html.erb` partial render the ZIP +
  City + State inputs plus hidden `latitude`/`longitude`/
  `city_match_successful` fields — picking a suggestion fills all six
  so the form can skip background geocoding. Editing the ZIP after a
  pick clears the hidden fields so the server falls back to
  `ZipLookup.geocode_with_fallback`. Not yet wired into any page; that
  happens in phases 2–4.

- **Your Practice: three new pages.** "Practice Details" is renamed to
  "Practice Information" and narrowed to its own page (practice name +
  "use practice name" toggle, website, required phone + optional
  extension, "show phone on profile" toggle). Accessibility and Social
  Media are promoted to their own pages with their own forms —
  Accessibility is now a 3-column alphabetized checkbox list of
  `accessibility_options`; Social Media is nine platform URL fields
  persisted to `therapists.social_media` jsonb. Routes:
  `/your-practice/practice-information`, `/your-practice/accessibility`,
  `/your-practice/social-media`.

### Changed
- **Your Practice sidebar order.** New order: Practice Information →
  Locations → Introduction → Clients & Availability → Accessibility →
  Fees & Payments → Services & Specialties → Social Media → FAQs.

## 2026-04-20

### Added
- **About You → Professional development: editable additional-training
  form.** Replaces the read-only placeholder. Therapists can enter up to
  three trainings, each with an optional year and a description (e.g.
  `C/NDT Certification`). Follows the same "hidden slot + add button"
  pattern as Education. New column `therapist_continuing_education.year`
  (nullable integer), migration
  `20260420000000_add_year_to_therapist_continuing_education`.

### Changed
- **Account settings: email change flow rebuilt.** The
  `/account-settings/update-email` page now lets users actually change
  their email instead of showing a "contact support" notice. Submitting
  a new address calls Supabase `PUT /auth/v1/user` (via
  `SupabaseAuth#request_email_change`) to send an 8-digit code to the
  new address. The page then swaps to an OTP input; verifying calls
  `POST /auth/v1/verify` with `type: "email_change"` and updates
  `users.email` in Rails. Pending changes persist in the session so
  users can leave and come back, and a "Use a different email" button
  discards state. Rate-limited at the controller layer.

## 2026-04-19

### Added
- `R2OrphanCleanupJob` (daily at 04:00 via `config/recurring.yml` +
  Avo action on the UserCredential resource) deletes R2 objects with no
  DB reference. Covers both the public `R2_HEADSHOTS_BUCKET_NAME` bucket
  (profile photos, prefix `profiles/`) and the private `ptd-credentials`
  bucket (credential docs, prefix `credentials/`). Safety rules: 24h age
  gate (no fresh uploads get touched), prefix-scoped listing, every
  deleted key logged at INFO. Docs at
  [`_docs/_background-jobs/r2_orphan_cleanup_job.md`](_docs/_background-jobs/r2_orphan_cleanup_job.md).

### Changed
- **Profile photo storage unified to the same key-only pattern as
  credentials.** `therapists.practice_image_url` column renamed to
  `practice_image_key`; the column now stores the R2 object key
  (e.g. `profiles/<uuid>/<timestamp>-<hash>.jpg`). Full URL is computed
  on demand in `Therapist#practice_image_url` from `R2_PUBLIC_URL` + key.
  Matches what Rails Active Storage / Shrine / Carrierwave do: provider
  independence, CDN flexibility, env safety, easier orphan cleanup. The
  `presigned_uploads_controller` now returns `{ presigned_url, key }`
  (no `public_url`); the JS controller saves the key; the account update
  endpoint responds with the computed URL for the UI to display.
  Pre-launch wipe of the column authorized by project owner.

### Security
- **Credential documents now upload to the private `ptd-credentials`
  R2 bucket** instead of the public `R2_HEADSHOTS_BUCKET_NAME` bucket.
  Previously `AboutYou::CredentialUploadsController` was writing state
  license / supervisor ID PDFs into the public profile-photo bucket and
  storing a permanent public URL in the DB, meaning any therapist's
  license document was readable by anyone who could guess the path.
  Upload now returns the R2 object key (not a URL); `credential_document`
  stores only that key. Admin-only download endpoint
  (`GET /admin-tools/credentials/:id/document`, routed to
  `AdminTools::CredentialDocumentsController#show`) mints a 5-minute
  presigned GET URL on demand and redirects. New R2 credential:
  `R2_CREDENTIALS_BUCKET_NAME`.
- Avo `UserCredential` resource has a new "Download" link that uses the
  same admin-only endpoint.

### Changed
- Enforced one-credential-per-therapist:
  - `Therapist has_many :user_credentials` → `has_one :user_credential`.
  - Added `validates :therapist_id, uniqueness: true` on `UserCredential`.
  - New unique index on `user_credentials.therapist_id` (DB-level guard
    against races).
  - Avo Therapist resource: `:has_many` → `:has_one`.
- Switching credential types (e.g. state_license → organization) now
  resets `credential_document`, `credential_document_original_name`,
  `credential_status` (→ `pending_review`), `verified_at`, and
  `pending_since`, on top of the existing blanking of the other type's
  fields. A type switch is effectively a new credential for verification.

### Changed
- All editable forms now stack fields vertically — one field per row.
  Removed `grid-cols-2` side-by-side layouts from primary credentials
  (state / license / expiration / org name / member ID / credential
  level), education (degree / graduation year), and account settings
  (first name / last name). Narrow fields keep `sm:w-1/2` (or `sm:w-32`
  for 4-digit year inputs) so they don't stretch the whole card.

### Changed
- Primary credential expiration dates are now month-precision only.
  Two plain text inputs (`MM` + `YYYY`, both using the `digits-only`
  Stimulus controller) replace the full-date picker on state-license,
  organization, and supervised credential types. The controller combines
  the two fields into the last day of the selected month and writes the
  existing `date` column (`license_expiration_date` /
  `organization_expiration_date`). Native `<input type="month">` was
  tried first but looked terrible.
- `UserCredential` has a new `GRACE_PERIOD` constant (2 weeks) and a
  `before_save` that computes `grace_expires_at = expiration_date.end_of_day
  + GRACE_PERIOD` from whichever column applies to the credential's type.

### Added
- `CredentialGraceExpirationJob` (in `app/jobs/`) scheduled daily at 03:00
  via `config/recurring.yml` (`expire_credentials_past_grace`). Flips any
  `PENDING_REVIEW` / `VERIFIED` credential past `grace_expires_at` to
  `EXPIRED`. Idempotent. Docs at
  [`_docs/_background-jobs/credential_grace_expiration_job.md`](_docs/_background-jobs/credential_grace_expiration_job.md)
  and [`_docs/_cron-jobs/expire_credentials_past_grace.md`](_docs/_cron-jobs/expire_credentials_past_grace.md).

### Removed
- `user_credentials.last_verified_expires_at` column (was an unused orphan).
  Migration also wipes the `user_credentials` table — pre-launch clean
  slate authorized by the project owner; no real users yet.

## 2026-04-17

### Changed
- Every text link now underlines on hover (in addition to the existing
  color change). Covers the Edit/Add links on About You and Your Practice
  section cards, the "Use a different email" link on OTP verify, the
  "Choose a plan" header link, the footer links, the Avo back-link, and
  the education page's Remove / Add another college controls. Dropdown
  menu items are unchanged — they keep their row-highlight hover.

### Added
- About You → Education page is now editable. Fields: `year_began_practice`
  (years of experience) plus up to two college/university entries with
  degree and graduation year. College picker is a WAI-ARIA combobox backed
  by a JSON search endpoint (`GET /about-you/colleges/search`). When a
  therapist can't find their school, the combobox offers an inline
  "Add '…' (pending review)" option that creates a `colleges` row with
  `status: "pending"` and attributes it to the submitting therapist. A
  "Pending review" badge renders next to any non-approved selection, both
  on the live dropdown and on the saved state.
- Year inputs (in-practice-since + graduation year) are plain 4-digit text
  boxes — no spinner arrows. `inputmode="numeric"`, `maxlength="4"`, and a
  new `digits-only` Stimulus controller strip any non-digits on the fly.
  Server-side, `Therapist#year_began_practice` and
  `TherapistEducation#graduation_year` must fall within 1940..current year
  (integer). `College` validates `name` presence + 120-char max and
  normalizes whitespace. `College.find_or_submit` case-insensitively
  matches existing names before creating a new pending row, preventing
  duplicate submissions.

### Changed
- Removed the dashboard page. Account Settings is now the landing page
  for signed-in users. Top nav "Dashboard" → "Your Account" linking to
  `/account-settings`. Logo, post-signin redirect, Avo admin redirect,
  and Avo header back-link all point to `account_settings_path`.
- Moved the Share button (profile-link dropdown) from the removed
  dashboard page into the layout header, positioned to the left of the
  avatar. Works on desktop; hidden under the mobile hamburger.
- Account Settings profile photo: added "Profile pic" label above the
  avatar, bumped avatar to 80×80, added upload icon to the Change
  button, removed the "JPEG or PNG. 5 MB max." helper text.
- Removed page titles (`content_for :page_header`) from every dashboard
  section page. Removed inner bordered box + "Your account" section
  title from the Account form; added a `border-t` divider above the
  Save button on the three editable forms (account, professional
  identity, primary credential).
- Fixed `account_settings_account_path` → `account_path` on the Account
  form (scope doesn't namespace URL helpers).

### Removed
- `DashboardController` and `app/views/dashboard/show.html.erb`.
- `dashboard` resource and `test_submit` route.
- Redundant "Account Settings" link from the avatar and mobile
  dropdowns (now covered by the top-nav "Your Account" item).

## 2026-04-16

### Added
- Admin panel using Avo (free/community edition) at `/avo`.
  Includes Avo resources for all core models (User, Therapist,
  Location, UserCredential, TherapistEducation,
  TherapistContinuingEducation, BusinessHour, ZipLookup) and all
  reference tables (Specialty, Service, Language, State, Profession,
  College, etc.). Access restricted to admin users via Supabase auth
  session + `is_admin` flag. Search enabled on all resources.
- Specialty and service category models, migrations, and Avo
  resources. SpecialtyCategory and ServiceCategory tables with
  join tables to associate specialties/services with their
  categories. Manageable through the admin panel.

## 2026-04-15

### Added
- Deep health check endpoint at `/health`
  ([`app/controllers/health_controller.rb`](app/controllers/health_controller.rb)).
  Validates DB connectivity and Solid Queue process readiness. Returns
  JSON `{"db":"ok","queue":"ok"}` with 200 when healthy, 503 when
  degraded. Safelisted from Rack::Attack throttling and silenced from
  Lograge request logs. Point a Better Stack uptime monitor at this
  endpoint.

### Changed
- Upgraded Sentry DSN missing-credential log from `info` to `warn` so
  it surfaces in Better Stack when error tracking is silently disabled
  in production.

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
