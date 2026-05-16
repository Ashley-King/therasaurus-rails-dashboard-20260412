class Avo::Resources::TherapistMessage < Avo::BaseResource
  self.title = :sender_email
  self.includes = [ :therapist ]

  def fields
    field :id, as: :id
    field :delivery_status, as: :select, options: TherapistMessage::STATUSES.index_by(&:itself), enum: nil
    field :delivery_attempts, as: :number, readonly: true
    field :sender_name, as: :text
    field :sender_email, as: :text
    field :sender_phone, as: :text
    field :body, as: :textarea
    field :page_url, as: :text, only_on: :show
    field :last_delivery_error, as: :textarea, only_on: :show
    field :delivered_at, as: :date_time, only_on: :show
    field :failed_at, as: :date_time, only_on: :show
    field :therapist, as: :belongs_to
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end

  def actions
    action Avo::Actions::RetryTherapistMessageDelivery
  end
end
