# Stripe (via the Pay gem)

Stripe is the only billing provider. The
[Pay gem](https://github.com/pay-rails/pay) wraps the Stripe SDK,
manages the subscription/customer/charge tables, and verifies +
processes webhooks. We add a small layer on top to translate Pay's
billing state into the app's `users.membership_status`. See
[`business-rules.md`](../business-rules.md) sections 5–7 and the
Trial / Billing rules.

## Credentials

All keys live in Rails encrypted credentials and are read with
`Rails.application.credentials.fetch(:KEY)` so a missing key raises
loudly instead of returning `nil`. See `credentials.example`.

| Key | Purpose |
|---|---|
| `STRIPE_PUBLISHABLE_KEY` | Browser-side publishable key. |
| `STRIPE_SECRET_KEY` | Server-side secret. Test in dev, live in prod. |
| `STRIPE_WEBHOOK_SECRET` | Verifies signatures on `POST /pay/webhooks/stripe`. |
| `STRIPE_PRICE_MONTHLY_ID` | Recurring price id, $17/month. |
| `STRIPE_PRICE_YEARLY_ID` | Recurring price id, $170/year (saves $34). |
| `STRIPE_PRODUCT_MONTHLY_ID` | Stripe Product id for the monthly price (reference only — not read by code). |
| `STRIPE_PRODUCT_YEARLY_ID` | Stripe Product id for the yearly price (reference only — not read by code). |

`config/initializers/stripe.rb` pins `Stripe.api_version` so a
Stripe-side default bump can't change behavior silently. It also fails
boot in production if any of the keys above is missing, and refuses to
start in development if `STRIPE_SECRET_KEY` is a `sk_live_…` key.

`config/initializers/pay.rb` bridges our top-level credential names
into the names Pay expects (`STRIPE_PRIVATE_KEY`, `STRIPE_SIGNING_SECRET`,
`STRIPE_PUBLIC_KEY`) via ENV at boot, so Pay's own resolver finds them.

## Pricing

One Stripe Product with two recurring prices: $17/month and $170/year.
The 14-day free trial applies to either price and is enforced by the
app (we refuse to issue a trialing Checkout session to any user who
already has a `Pay::Subscription` row).

## Stripe Tax

Always on. Every Checkout session passes `automatic_tax: { enabled: true }`
and the Customer Portal is configured the same way. US-only in phase one.

## Webhook endpoint

`POST /pay/webhooks/stripe` — auto-mounted by Pay (`Pay.routes_path = "/pay"`,
`Pay.automount_routes = true`). Pay's webhook controller:

1. Reads the raw body and verifies the signature against
   `STRIPE_SIGNING_SECRET`.
2. Persists the event to `pay_webhooks` (idempotent: the event id is
   the dedupe key — re-deliveries are dropped).
3. Dispatches to Pay's built-in handlers, which sync customer +
   subscription + charge state into `pay_customers` /
   `pay_subscriptions` / `pay_charges`.
4. Fires app-side subscribers registered in
   [`config/initializers/billing_subscribers.rb`](../../config/initializers/billing_subscribers.rb).

## App-side subscribers

The single writer for `users.membership_status` lives in
[`BillingSync`](../../app/services/billing_sync.rb) and is called
exclusively from `billing_subscribers.rb` (after Pay finishes its own
sync). Mapping:

| Stripe `subscription.status`        | `users.membership_status` |
|-------------------------------------|---------------------------|
| `trialing`                          | `trialing_member`         |
| `active`, `past_due`                | `pro_member`              |
| `canceled`, `unpaid`, `incomplete`, |                           |
| `incomplete_expired`, `paused`, or  |                           |
| no subscription at all              | `member`                  |

`past_due` stays `pro_member` (and therefore public) through Stripe's
smart-retry window. Only `unpaid` (terminal) or `canceled` drops the
user back to `member`.

Subscribers also:
- Ping `:admin` on cancel (`stripe.customer.subscription.deleted`).
- Ping `:admin` on reactivation (a checkout session whose subscription
  carries `metadata.reactivation = "true"`, which we stamp in
  `StartTrialController#checkout` for users who already used their
  free trial).
- Send the therapist a `PlanChangeScheduledMailer` on
  `stripe.subscription_schedule.created` (portal-initiated plan change
  queued to end of period — see Plan change rules in
  [`business-rules.md`](../business-rules.md)).
- Capture exceptions and ping `:stripe_errors` on Discord; re-raise so
  Better Stack also sees them via the Sentry SDK.

## Pay mailers we use

Pay ships built-in mailers; we override the templates under
`app/views/pay/user_mailer/` to match our copy. `config/initializers/pay.rb`
toggles which mailers Pay sends.

| Mailer | Default? | Trigger |
|---|---|---|
| `subscription_trial_will_end` | on | `customer.subscription.trial_will_end` (3 days before trial end) — our pre-charge reminder. |
| `payment_failed` | on | `invoice.payment_failed` — our dunning email. |
| `subscription_renewing` | on (yearly only) | `invoice.upcoming` for renewing subs. |
| `payment_action_required` | on | 3DS / extra auth needed. |
| `receipt` | **off** | Stripe sends its own. |
| `refund` | **off** | Stripe sends its own. |

Plus our own (not from Pay):

| Mailer | Trigger |
|---|---|
| `PlanChangeScheduledMailer` | `stripe.subscription_schedule.created` — confirms a portal-initiated plan change and the date it takes effect. |

## Customer Portal configuration

Reached via `POST /account-settings/membership/portal`
([`AccountSettings::MembershipsController#portal`](../../app/controllers/account_settings/memberships_controller.rb)),
which calls `current_user.payment_processor.billing_portal(return_url:)`
and redirects. The button is shown on the Membership page once the
user has a `Pay::Customer` with a Stripe `processor_id`.

Configured in the Stripe Dashboard (Billing → Customer portal). Phase
one settings:

- Cancel subscription: on (cancel at end of billing period)
- Update payment method: on
- View invoices: on
- Automatic tax: on
- Customer information (address): on (required by automatic tax)
- Subscription update: on. Both monthly and yearly listed as switchable
  destinations.
  - **Proration: "No charges or credits"** (`proration_behavior: none`).
    Plan changes apply at the next billing cycle; no instant charges,
    no refunds for unused time.
  - **Downgrades → "When switching to a cheaper plan": Wait until end
    of billing period to update.**
  - **Downgrades → "When switching to a shorter interval period": Wait
    until end of billing period to update.**

Stripe does NOT support per-source-price restrictions in the portal
config (the `subscription_update.products[].prices` array is a flat
list of allowed destinations — there's no way to say "monthly users can
switch to yearly but yearly users cannot switch to monthly"). So both
directions are technically self-serve. The "wait until end of billing
period" setting prevents Stripe from issuing surprise refund credits
when a yearly customer downgrades — they pay out the year they bought,
then the change kicks in at renewal.

When a customer schedules a change, Stripe automatically creates a
Subscription Schedule and fires `subscription_schedule.created`. We
subscribe to that event in `billing_subscribers.rb` and send the
therapist a `PlanChangeScheduledMailer` confirming the change and the
effective date (Stripe doesn't send a scheduled-change email by
default). The actual transition fires `customer.subscription.updated`
at the period boundary, which Pay's existing handler picks up.

If we ever want to enforce direction (truly block yearly → monthly
self-serve), the path is two portal configurations selected per session
via the `configuration:` parameter on
`payment_processor.billing_portal`. See
[`business-rules.md`](../business-rules.md#plan-change-rules).

## Testing locally with the Stripe CLI

```sh
# Forward live webhook deliveries from a local Stripe test session.
stripe listen --forward-to http://localhost:3000/pay/webhooks/stripe

# Manually fire test events.
stripe trigger checkout.session.completed
stripe trigger customer.subscription.trial_will_end
stripe trigger invoice.payment_failed
```

The CLI prints the webhook signing secret on first run; copy it into
`STRIPE_WEBHOOK_SECRET` in the dev credentials.

## Idempotency notes

- Pay's `pay_webhooks` table dedupes by Stripe event id. Re-deliveries
  are dropped before any handler runs.
- Pay's own handlers re-apply the latest Stripe-side state, so they
  are safe to re-run.
- `BillingSync.sync_membership_status!` only writes when the computed
  value differs from the stored one.
- `StripeService` and our hand-rolled handlers were removed; Pay owns
  this surface area now.

## Cross-references

- [`notifications.md`](./notifications.md) — `:stripe_errors` and
  `:admin` Discord channels.
- [`business-rules.md`](../business-rules.md) — membership states,
  public-visibility rules, trial behavior, dunning rules.
