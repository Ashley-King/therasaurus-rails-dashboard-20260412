# Single writer for `users.membership_status` based on Pay's
# `Pay::Subscription` state. Called from Pay::Webhooks subscribers in
# `config/initializers/billing_subscribers.rb` after Pay finishes its
# own sync.
#
# Membership state mapping (per `_docs/business-rules.md`):
#
# | Stripe sub.status                                | membership_status   |
# |--------------------------------------------------|---------------------|
# | trialing                                         | trialing_member     |
# | active, past_due                                 | pro_member          |
# | canceled, unpaid, incomplete, incomplete_expired,| member              |
# | paused, anything else, or no subscription at all | member              |
#
# `past_due` stays `pro_member` (and therefore public) through Stripe's
# smart-retry window. Only `unpaid` (terminal) or `canceled` drops the
# user back to `member`.
#
# Idempotent: only writes when the computed status differs from the
# stored value.
class BillingSync
  TRIALING_STATUSES = %w[trialing].freeze
  PAID_STATUSES = %w[active past_due].freeze

  def self.sync_membership_status!(user)
    return unless user

    subscription = user.payment_processor&.subscription
    target = membership_for(subscription)

    return if user.membership_status == target

    user.update!(membership_status: target)
  end

  def self.membership_for(subscription)
    return "member" if subscription.nil?

    case subscription.status
    when *TRIALING_STATUSES then "trialing_member"
    when *PAID_STATUSES     then "pro_member"
    else                         "member"
    end
  end
end
