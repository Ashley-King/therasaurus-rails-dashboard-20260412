# Stripe API version pin + boot guards. Pay handles the actual
# `Stripe.api_key` assignment via its own initializer; this file only
# covers things Pay does NOT manage. See `_docs/_processes/stripe.md`.

# Pin the Stripe API version so a Stripe-side default bump can't change
# behavior silently. Bump deliberately when you want a new version, after
# reading the Stripe API changelog.
Stripe.api_version = "2026-04-22.dahlia"

# Guard against a live secret key landing in development by accident.
secret_key = Rails.application.credentials[:STRIPE_SECRET_KEY].to_s
if Rails.env.development? && secret_key.start_with?("sk_live_")
  raise "STRIPE_SECRET_KEY is a live key in development; use a test key (sk_test_...)"
end

# Production-only: fail boot if any Stripe credential we depend on is
# missing, so a misconfigured deploy 500s loudly instead of silently
# 400ing every webhook.
if Rails.env.production?
  %i[
    STRIPE_SECRET_KEY
    STRIPE_PUBLISHABLE_KEY
    STRIPE_WEBHOOK_SECRET
    STRIPE_PRICE_MONTHLY_ID
    STRIPE_PRICE_ANNUAL_ID
  ].each { |key| Rails.application.credentials.fetch(key) }
end
