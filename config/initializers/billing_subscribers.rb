# App-side reactions to Stripe webhook events. Pay handles persisting
# Pay::Customer / Pay::Subscription state; we hook in afterward to:
#
# 1. Re-sync `users.membership_status` (single writer; see BillingSync).
# 2. Ping `:admin` on Discord on cancel and reactivation.
# 3. Email the therapist when they schedule a plan change in the
#    portal (Stripe doesn't send a scheduled-change email by default).
# 4. Catch-all `:stripe_errors` ping if a subscriber raises (so a
#    silent code bug doesn't go un-noticed).
#
# Subscribers run AFTER Pay's own handlers, so by the time we run, the
# `pay_subscriptions` row is up to date.
#
# Wrapped in `to_prepare` so they re-register cleanly on Rails reload
# in development.
Rails.application.reloader.to_prepare do
  # Resolve a Stripe webhook event to a User via Pay::Customer.
  user_for = lambda do |event|
    customer_id = event.data.object.respond_to?(:customer) ? event.data.object.customer : nil
    next unless customer_id

    Pay::Customer.find_by(processor: "stripe", processor_id: customer_id)&.owner
  end

  with_error_capture = lambda do |label, &blk|
    blk.call
  rescue StandardError => e
    Notifier.notify(
      :stripe_errors,
      "Subscriber #{label} failed: #{e.class}: #{e.message}"
    )
    raise
  end

  Pay::Webhooks.delegator.subscribe("stripe.checkout.session.completed") do |event|
    with_error_capture.call("checkout.session.completed") do
      user = user_for.call(event)
      next unless user

      BillingSync.sync_membership_status!(user)

      # Reactivation ping. We stamp `metadata.reactivation = "true"` on
      # the Stripe subscription when the user comes back without a
      # second free trial; here we read it off the persisted Pay row.
      sub_id = event.data.object.subscription
      next unless sub_id

      pay_sub = Pay::Subscription.find_by(processor_id: sub_id)
      next unless pay_sub&.metadata.is_a?(Hash) && pay_sub.metadata["reactivation"] == "true"

      Notifier.notify(
        :admin,
        "Therapist user_id=#{user.id} reactivated their subscription " \
        "(stripe_subscription_id=#{sub_id})."
      )
    end
  end

  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.created") do |event|
    with_error_capture.call("customer.subscription.created") do
      user = user_for.call(event)
      BillingSync.sync_membership_status!(user) if user
    end
  end

  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.updated") do |event|
    with_error_capture.call("customer.subscription.updated") do
      user = user_for.call(event)
      BillingSync.sync_membership_status!(user) if user
    end
  end

  Pay::Webhooks.delegator.subscribe("stripe.customer.subscription.deleted") do |event|
    with_error_capture.call("customer.subscription.deleted") do
      user = user_for.call(event)
      next unless user

      BillingSync.sync_membership_status!(user)

      Notifier.notify(
        :admin,
        "Therapist user_id=#{user.id} canceled their subscription " \
        "(stripe_subscription_id=#{event.data.object.id})."
      )
    end
  end

  # When a therapist schedules a plan change in the Customer Portal
  # (monthly ↔ yearly), Stripe creates a Subscription Schedule and
  # waits until the end of the current period to apply it. Email the
  # therapist so they have a record of what they did and when it
  # takes effect — Stripe does not send this email by default.
  Pay::Webhooks.delegator.subscribe("stripe.subscription_schedule.created") do |event|
    with_error_capture.call("subscription_schedule.created") do
      schedule = event.data.object
      pay_customer = Pay::Customer.find_by(processor: "stripe", processor_id: schedule.customer)
      user = pay_customer&.owner
      next unless user

      # The upcoming phase carries the new price + start time.
      upcoming_phase = schedule.phases.find { |p| p.start_date && Time.at(p.start_date) > Time.current }
      next unless upcoming_phase

      effective_at = Time.at(upcoming_phase.start_date)

      new_amount_label =
        begin
          item = upcoming_phase.items&.first
          price = item && ::Stripe::Price.retrieve(item.price)
          if price&.unit_amount && price.currency
            amount = price.unit_amount.to_i / 100.0
            interval = price.recurring&.interval
            formatted = price.currency.to_s.downcase == "usd" ? "$#{format('%.0f', amount)}" : "#{format('%.2f', amount)} #{price.currency.to_s.upcase}"
            interval ? "#{formatted}/#{interval}" : formatted
          end
        rescue ::Stripe::StripeError
          nil
        end

      PlanChangeScheduledMailer.with(
        user: user,
        effective_at: effective_at,
        new_amount_label: new_amount_label
      ).notify.deliver_later
    end
  end
end
