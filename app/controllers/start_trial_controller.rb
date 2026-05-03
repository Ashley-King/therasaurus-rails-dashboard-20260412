# Post-Create-Account interstitial that offers the 14-day free trial.
# Therapists who already used their trial (any prior `Pay::Subscription`)
# and don't have an active subscription land on a "subscribe" variant of
# the same page — no second free trial.
class StartTrialController < ApplicationController
  include Authentication

  layout "auth"

  before_action :require_auth
  before_action :require_profile
  before_action :redirect_if_currently_subscribed

  ALLOWED_PLANS = %w[monthly yearly].freeze

  # GET /start-trial
  def show
    @reactivation = current_user.pay_subscriptions.exists?
  end

  # POST /start-trial/checkout
  def checkout
    plan = ALLOWED_PLANS.include?(params[:plan]) ? params[:plan] : "monthly"
    trial = current_user.pay_subscriptions.none?
    price_id = price_id_for(plan)

    subscription_metadata = { user_id: current_user.id, plan: plan }
    subscription_metadata[:reactivation] = "true" unless trial

    subscription_data = { metadata: subscription_metadata }
    subscription_data[:trial_period_days] = 14 if trial

    session = current_user.payment_processor.checkout(
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      subscription_data: subscription_data,
      payment_method_collection: "always",
      automatic_tax: { enabled: true },
      customer_update: { address: "auto", name: "auto" },
      success_url: trial_started_url,
      cancel_url: start_trial_url,
      client_reference_id: current_user.id,
      metadata: subscription_metadata
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue ::Stripe::StripeError => e
    Notifier.notify(
      :stripe_errors,
      "Checkout session create failed for user #{current_user.id}: #{e.class}: #{e.message}"
    )
    redirect_to start_trial_path,
                alert: "We couldn't start your trial right now. Please try again in a moment."
  end

  # POST /start-trial/skip
  def skip
    redirect_to account_settings_path, notice: "You can start your free trial any time from Account Settings."
  end

  private

  def price_id_for(plan)
    case plan
    when "monthly" then Rails.application.credentials.fetch(:STRIPE_PRICE_MONTHLY_ID)
    when "yearly"  then Rails.application.credentials.fetch(:STRIPE_PRICE_YEARLY_ID)
    end
  end

  # Bounce users with an active trial / paid sub / past_due. Users whose
  # subscription is `canceled` or has `ends_at` in the past stay on the
  # page and get the reactivation variant.
  def redirect_if_currently_subscribed
    sub = current_user.payment_processor&.subscription
    return unless sub && %w[trialing active past_due].include?(sub.status)

    redirect_to account_settings_path
  end
end
