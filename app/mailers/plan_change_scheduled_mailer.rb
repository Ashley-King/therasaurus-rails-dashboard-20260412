# Sent when a therapist schedules a plan change in the Stripe Customer
# Portal (e.g., monthly → yearly or yearly → monthly). Stripe queues the
# change to the end of the current billing period; we email so the
# therapist has a record of what they did and when it will take effect.
#
# Triggered from the `stripe.subscription_schedule.created` Pay
# webhook subscriber in `config/initializers/billing_subscribers.rb`.
class PlanChangeScheduledMailer < ApplicationMailer
  def notify
    @user = params.fetch(:user)
    @effective_at = params[:effective_at]      # Time, when the change kicks in
    @new_amount_label = params[:new_amount_label] # e.g. "$170/year"; may be nil

    mail(
      to: @user.email,
      subject: "Your TheraSaurus plan change is scheduled"
    )
  end
end
