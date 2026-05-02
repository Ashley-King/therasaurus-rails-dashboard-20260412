class User < ApplicationRecord
  # Pay billable. Stripe is the only processor in phase one.
  # Pay::Customer + Pay::Subscription rows hold all billing state;
  # `users.membership_status` is the app-side denorm we read from
  # everywhere else (kept in sync by the Pay::Webhooks subscriber in
  # `config/initializers/billing_subscribers.rb`).
  pay_customer default_payment_processor: :stripe

  has_one :therapist, dependent: :destroy

  # Convenience: the Pay::Subscription Pay tracks for this user (if any).
  # Pay also exposes `subscribed?`, `on_trial?`, etc.
  def stripe_subscription
    payment_processor&.subscription
  end
end
