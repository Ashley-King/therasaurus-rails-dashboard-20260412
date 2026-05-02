require "mail"

# Pay configuration. See https://github.com/pay-rails/pay and
# `_docs/_processes/stripe.md`.
#
# Pay reads Stripe credentials via `Pay::Stripe.private_key` /
# `signing_secret`, which check `ENV["STRIPE_PRIVATE_KEY"]` and
# `Rails.application.credentials.dig(:stripe, :private_key)`. Our
# credentials live at the top level (`STRIPE_SECRET_KEY`,
# `STRIPE_WEBHOOK_SECRET`) so we bridge them into the names Pay
# expects via ENV at boot. We use `fetch` so missing keys raise.
ENV["STRIPE_PRIVATE_KEY"] ||= Rails.application.credentials.fetch(:STRIPE_SECRET_KEY)
ENV["STRIPE_SIGNING_SECRET"] ||= Rails.application.credentials.fetch(:STRIPE_WEBHOOK_SECRET)
if Rails.application.credentials[:STRIPE_PUBLISHABLE_KEY]
  ENV["STRIPE_PUBLIC_KEY"] ||= Rails.application.credentials[:STRIPE_PUBLISHABLE_KEY]
end

Pay.setup do |config|
  config.application_name = "TheraSaurus"
  config.business_name = "TheraSaurus"
  config.business_address = "TheraSaurus"
  config.support_email = "support@therasaurus.org"

  # Built-in mailers we keep on (defaults):
  # - subscription_renewing: pre-charge reminder for renewing subs
  # - subscription_trial_will_end: reminder 3 days before trial ends
  # - payment_failed: dunning email on failed charges
  # - payment_action_required: 3DS / extra auth
  #
  # Disabled in phase one (Stripe sends its own):
  config.emails.receipt = false
  config.emails.refund = false
end
