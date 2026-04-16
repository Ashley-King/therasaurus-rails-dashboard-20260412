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
    field :stripe_customer_id, as: :text
    field :trial_ends_at, as: :date_time
    field :therapist, as: :has_one
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
