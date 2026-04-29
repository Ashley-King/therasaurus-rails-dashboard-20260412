# Notifications

Internal-only notifications for the dev team (just me). Two separate
systems with a clean split:

1. **Intentional domain events** → Discord via `Notifier.notify`.
   Things we *want* to glance at even when nothing is broken: new
   signup, user write-in, rate limit tripped. Low-volume, scrollable
   channels organized by domain.
2. **Uncaught exceptions** → Better Stack Error tracking (Sentry SDK
   under the hood) with alerts delivered through Better Stack's
   native channels: email and the Better Stack mobile app. **Not
   routed to Discord.** Discord has no stack traces, no grouping, no
   resolve button — BetterStack does. The `#errors` channel exists
   but is reserved for future manual use; nothing auto-posts there.

Keeping these separate means the `Notifier` service only ever carries
intentional, actionable signals, and the exception firehose lives in
the tool built for exceptions.

## Discord channels

Each channel maps to a webhook URL stored in Rails credentials. The
full list lives in [`app/services/notifier.rb`](../../app/services/notifier.rb)
as the `Notifier::CHANNELS` constant — that file is the single source
of truth.

| Symbol | Credential key | Purpose |
|---|---|---|
| `:admin` | `ADMIN_WEBHOOK` | General admin events, new signups, rate limit trips, anything without a more specific home |
| `:errors` | `ERRORS_WEBHOOK` | Reserved for future manual use. Errors go to Better Stack's native alerting, not Discord. Nothing auto-posts here. |
| `:stripe_errors` | `CLOUDFLARE_STRIPE_ERRORS_WEBHOOK` | Stripe webhook failures, payment errors |
| `:college_write_in` | `COLLEGE_WRITE_IN_WEBHOOK` | User submitted a college not in the DB |
| `:feature_requests` | `FEATURE_REQUESTS_WEBHOOK` | Feature request form submissions |
| `:email_service` | `EMAIL_SERVICE_WEBHOOK` | Resend delivery / bounce issues |
| `:geocoding` | `GEOCODING_WEBHOOK` | Geocoding job failures, Supabase geocoding issues |
| `:insurance_write_in` | `INSURANCE_WRITE_IN_WEBHOOK` | User submitted an insurance provider not in the DB |
| `:search_index_service` | `SEARCH_INDEX_SERVICE_WEBHOOK` | Meilisearch sync failures, reindex results |
| `:supabase` | `SUPABASE_WEBHOOK` | Supabase auth/RLS/connection issues |
| `:payment_methods` | `PAYMENT_METHODS_WEBHOOK` | User submitted a payment method not in the DB |
| `:services` | `SERVICES_WEBHOOK` | User submitted a service not in the DB |
| `:specialties` | `SPECIALTIES_WEBHOOK` | User submitted a specialty not in the DB |

## How to send a notification

```ruby
Notifier.notify(:admin, "New signup: therapist ##{t.id}")
Notifier.notify(:college_write_in, "User submitted '#{name}'")
```

Delivery is always async via
[`NotifierJob`](../../app/jobs/notifier_job.rb). A slow or broken
Discord webhook can never block a request. Failed deliveries are
logged (`event=notifier.delivery_failed`) and discarded — no retries,
no noise.

Unknown channel symbols raise `Notifier::UnknownChannel` immediately
so typos are caught at call time.

## Currently wired

- **New signup** → `:admin`
  ([`CreateAccountController#create`](../../app/controllers/create_account_controller.rb))
- **Rate limit tripped** → `:admin`
  ([`config/initializers/rack_attack.rb`](../../config/initializers/rack_attack.rb)).
  One ping per IP per hour via a `Rails.cache` cooldown so one scraper
  can't flood the channel.
- **Feature request submitted** → kind-specific channel
  ([`FeatureRequestsController#create`](../../app/controllers/feature_requests_controller.rb)).
  Routing map: `specialty` → `:specialties`, `service` → `:services`,
  `insurance_company` → `:insurance_write_in`, `college` →
  `:college_write_in`, `general` → `:feature_requests`.

## Better Stack error tracking — setup

Better Stack error tracking is Sentry-SDK compatible. The setup page
in Better Stack literally says *"Integrate Better Stack Error
tracking using the Sentry SDK for Rails, using the following DSN"*.
So we use the standard `sentry-ruby` + `sentry-rails` gems pointed at
a Better Stack DSN — no Better-Stack-specific gem exists.

**Wired up:**

- `sentry-ruby` and `sentry-rails` in the Gemfile
- [`config/initializers/sentry.rb`](../../config/initializers/sentry.rb) —
  production-only, reads `BETTER_STACK_ERRORS_DSN` from credentials,
  `traces_sample_rate: 0.0` (errors only, no performance tracing),
  `send_default_pii: false`, `report_rescued_exceptions: false`.
  Respects Rails' `filter_parameter_logging` so anything scrubbed
  from logs is also scrubbed from errors.

**Alerting — done in the Better Stack dashboard, not in code:**

- [ ] Add your email as an alert recipient for new error groups.
- [ ] Install the Better Stack mobile app and enable push
      notifications for errors.

**Verify (after first production deploy):**

- [ ] Trigger a test exception in production — e.g. a temporary
      `raise "hello"` in a dev-only route, or via the Rails console:
      `Sentry.capture_message("Hello Better Stack, this is a test")`.
- [ ] Confirm the event lands in Better Stack Error tracking.
- [ ] Confirm you receive the email / push alert.

**Deliberately not done:**

- Discord routing for errors. Better Stack's native alerting covers
  email + mobile push, which is all a solo dev needs for error
  triage. Adding a Discord shim would just duplicate the signal in a
  worse format (no stack trace, no grouping).
- Performance tracing. `traces_sample_rate` is 0. Flip to a small
  value (0.05–0.1) later if performance regressions become a real
  concern.
- Source map upload / release tagging. `release` reads `GIT_REVISION`
  if set but we're not actively wiring it up. Add when Kamal deploys
  start surfacing "which deploy broke it" questions.

## What intentionally does *not* use Notifier

- Background job failures — Sentry SDK catches the raised exception
  and ships it to Better Stack. Don't add parallel routing.
- Uncaught exceptions in controllers — same.
- Log lines — already shipped to Better Stack via `logtail-rails`.
  See [`logging.md`](./logging.md).
