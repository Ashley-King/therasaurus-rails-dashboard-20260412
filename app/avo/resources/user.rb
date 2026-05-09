class Avo::Resources::User < Avo::BaseResource
  self.title = :email
  self.search = {
    query: -> { query.ransack(email_cont: params[:q], m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :email, as: :text
    field :is_admin, as: :boolean
    field :is_banned, as: :boolean
    field :membership_status, as: :select, options: {
      "Member": "member",
      "Trialing Member": "trialing_member",
      "Pro Member": "pro_member"
    }
    field :pay_stripe_customer_id,
      as: :text,
      name: "Stripe Customer ID",
      only_on: :show,
      format_using: -> { record.payment_processor&.processor_id.presence || "Not set" }
    field :pay_subscription_status,
      as: :text,
      name: "Current Subscription Status",
      only_on: :show,
      format_using: -> { record.payment_processor&.subscription&.status.presence || "Not set" }
    field :pay_trial_ends_at,
      as: :text,
      name: "Current Trial Ends",
      only_on: :show,
      format_using: -> {
        trial_ends_at = record.payment_processor&.subscription&.trial_ends_at
        trial_ends_at.present? ? I18n.l(trial_ends_at.to_date, format: :long) : "Not set"
      }
    field :therapist, as: :has_one
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
