# Billing Lifecycle QA

Use this checklist to review the full billing flow before launch and
after any billing change.

## Goal

Review the user screens, Stripe-hosted screens, Rails emails, Stripe
emails, webhook events, and app state for the paid membership lifecycle.

## Setup

Use Stripe test mode.

Run Rails:

```sh
mise exec -- bin/rails server
```

Forward Stripe webhooks to the local app:

```sh
stripe listen --forward-to http://localhost:3000/pay/webhooks/stripe
```

If Stripe prints a new `whsec_...` value, save it in local Rails
credentials as `STRIPE_WEBHOOK_SECRET` and restart Rails.

Development sends Rails email through Resend. Watch Resend activity for
Rails-owned emails.

Stripe sandbox customer emails are not sent to every address by default.
Use a Stripe team member email or an email on a verified domain when you
need to review Stripe customer emails.

## Record During Review

- Test user email.
- Stripe customer id.
- Stripe subscription id.
- Plan selected.
- Screenshots of app screens.
- Screenshots of Stripe Checkout and Customer Portal screens.
- Resend activity for Rails emails.
- Stripe customer email log.
- Stripe CLI webhook output.
- App membership status after each step.

## Scenario 1: Trial Begins

### Steps

1. Create or sign in as a fresh therapist user.
2. Complete enough profile setup to reach `/start-trial`.
3. Select monthly first.
4. Complete Stripe Checkout with test card `4242 4242 4242 4242`.
5. Return to `/trial-started`.
6. Continue to Account Settings.
7. Open Membership.
8. Open the Stripe Customer Portal.

### Expected Stripe Events

- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`

### Expected App State

- `users.membership_status` becomes `trialing_member`.
- Membership page says the user is on a free trial.
- Trial end date is visible.
- First charge date is visible.
- Public profile is eligible to be online if profile rules are met.

### Expected Emails

- No Rails email is expected at trial start.
- Stripe may send a trial or receipt email only if Stripe sandbox email
  rules allow it for the customer email.

### Review

- Checkout clearly says there is a 14-day trial.
- Checkout collects a card before starting the trial.
- Trial Started page works even if webhooks are still processing.
- Membership page has a working Manage Subscription button.
- Customer Portal shows allowed actions only.

## Scenario 2: User Chooses Or Updates Plan During Trial

This app does not currently charge immediately during trial. A user can
choose a plan at checkout or change the subscription plan in the Customer
Portal while the trial continues.

### Steps

1. Use a user with a trialing subscription.
2. Open Membership.
3. Open the Stripe Customer Portal.
4. Switch monthly to yearly.
5. Return to the app.
6. Repeat yearly to monthly if that option is enabled in the portal.

### Expected Stripe Events

- `subscription_schedule.created`
- Later, at the effective date, `customer.subscription.updated`

### Expected App State

- The subscription stays `trialing`.
- Trial end date does not move because portal config uses
  `trial_update_behavior: continue_trial`.
- The scheduled plan change is visible in Stripe.

### Expected Emails

- Rails sends `PlanChangeScheduledMailer` through Resend.
- Stripe does not send this scheduled-change email.

### Review

- The portal does not let the user edit their email.
- Customer updates are limited to name, address, and tax id.
- Proration is off.
- Downgrades wait until the end of the billing period.
- The Rails email says what will change and when.

## Scenario 3: Lifetime Free Coupon For First Users

Use this for comped founding users. The current app does not show a
promotion-code field in Stripe Checkout. Until that changes, apply the
coupon manually in Stripe after the user starts a trial or subscription.

### Stripe Setup

Create a 100% off forever coupon in test mode:

```sh
stripe coupons create \
  -d percent_off=100 \
  -d duration=forever \
  -d name="Founding user lifetime free"
```

Optional: limit the coupon to the TheraSaurus products in Stripe so it
cannot accidentally apply to unrelated future products.

If the app later supports customer-entered codes, create a promotion code
from the coupon and add `allow_promotion_codes: true` to Checkout. Do not
document or share a public code until that path is intentionally built.

### Steps

1. Use a trialing or active founding-user subscription.
2. Copy the Stripe subscription id.
3. Apply the coupon to the subscription:

```sh
stripe subscriptions update sub_... \
  -d "discounts[0][coupon]"=<coupon_id>
```

4. Open the Stripe subscription.
5. Open the next upcoming invoice preview.
6. Open Membership in the app.
7. Open the Stripe Customer Portal.

### Expected Stripe Events

- `customer.subscription.updated`
- `invoice.updated` or later invoice events when Stripe creates the next
  invoice.

### Expected App State

- The user remains `trialing_member` during trial.
- The user becomes or stays `pro_member` after the subscription is active.
- The coupon is visible on the Stripe subscription.
- Upcoming invoices show a 100% discount.
- Amount due is $0 while the coupon remains active.
- Public profile access stays active as long as the subscription is
  trialing, active, or past_due.

### Expected Emails

- Rails does not send a special coupon email.
- Stripe invoice or receipt emails may show the discount if Stripe sends
  them for the customer and mode.

### Review

- The coupon duration is `forever`.
- The discount is 100%.
- The coupon is attached to the intended subscription.
- The coupon is not a one-time or repeating-month discount.
- The user cannot edit their account email in the Customer Portal.
- The next invoice total is $0.
- The app still treats the user as a normal active member.

## Scenario 4: User Cancels During Trial Or Active Membership

### Steps

1. Use a trialing or active subscription.
2. Open Membership.
3. Open the Stripe Customer Portal.
4. Cancel the subscription.
5. Return to the app.
6. Wait for the webhook to process.

### Expected Stripe Events

- `customer.subscription.updated` when cancellation is scheduled.
- `customer.subscription.deleted` at the actual end date.

### Expected App State

- If cancellation is scheduled for period end, the user keeps access until
  the period or trial actually ends.
- When Stripe sends `customer.subscription.deleted`,
  `users.membership_status` becomes `member`.
- Public profile is no longer eligible to be online after cancellation is
  complete.

### Expected Emails And Notifications

- Rails sends an admin Discord notification once for cancellation.
- Stripe may send customer cancellation email depending on Dashboard
  email settings and sandbox email rules.
- Rails does not send a customer cancellation email.

### Review

- Portal cancellation wording is clear.
- Cancellation reasons are available.
- The app does not drop access too early.
- The app drops access after Stripe completes cancellation.

## Scenario 5: Trial Ends

Use Stripe test clocks for this. Do not wait 14 days.

### Dashboard Path

Stripe Dashboard -> Billing -> Subscriptions -> choose test subscription
-> Run simulation.

### Steps

1. Create a simulated customer with a card.
2. Create a subscription with a trial.
3. Advance the clock to 3 days before trial end.
4. Confirm `customer.subscription.trial_will_end`.
5. Advance the clock to the trial end.
6. Confirm the subscription moves to active.
7. Confirm the first paid invoice and payment events.

### Expected Stripe Events

- `customer.subscription.trial_will_end`
- `invoice.upcoming`
- `invoice.updated`
- `customer.subscription.updated`
- Payment or invoice events when the trial converts.

### Expected App State

- Trial warning email is queued when
  `customer.subscription.trial_will_end` is processed.
- User becomes `pro_member` after Stripe marks the subscription active.
- Membership page switches from first charge to next charge.

### Expected Emails

- Rails sends Pay's `subscription_trial_will_end` email through Resend.
- Stripe may send its own trial reminder if customer email settings and
  sandbox email rules allow it.
- Stripe sends receipts in live mode if receipt settings are enabled.

### Review

- Rails trial email copy is correct.
- Stripe trial email copy does not conflict with Rails copy.
- The user has a clear cancellation path before charge.
- The app state updates after the webhook.

## Scenario 6: Failed Payment

### Steps

1. Use Stripe test cards or a test clock scenario that creates a failed
   invoice payment.
2. Confirm the webhook reaches Rails.
3. Open Account Settings.
4. Open Membership.

### Expected Stripe Events

- `invoice.payment_failed`
- `customer.subscription.updated`

### Expected App State

- Subscription becomes `past_due`.
- `users.membership_status` stays `pro_member`.
- Public profile stays eligible during Stripe's retry window.
- Account Settings shows the failed-payment banner.

### Expected Emails

- Rails sends Pay's payment-failed email through Resend.
- Stripe may send its own failed-payment email depending on Dashboard
  settings and sandbox email rules.

### Review

- Failed-payment banner tells the user to update their card.
- Customer Portal lets the user update payment method.
- App does not remove the public profile while status is `past_due`.

## Smoke Tests With Triggered Events

Use these only to confirm the endpoint is alive. They do not fully test
real app state.

```sh
stripe trigger customer.subscription.trial_will_end
stripe trigger invoice.payment_failed
stripe trigger customer.subscription.deleted
```

Expected result in the Stripe CLI:

```text
[200 POST] OK
```

## Final Prelaunch Pass

- Test mode webhook exists or local `stripe listen` is running.
- Live webhook is created after deployment.
- Live `STRIPE_WEBHOOK_SECRET` is set from the live endpoint.
- Customer Portal test and live configs match.
- Stripe support email and support URL are real.
- Stripe customer email settings are reviewed in the Dashboard.
- Lifetime-free coupon exists in test and live mode if founding users need
  comped access.
- Resend sender domain is verified.
- Rails emails render with correct links.
- Better Stack catches webhook job failures.
