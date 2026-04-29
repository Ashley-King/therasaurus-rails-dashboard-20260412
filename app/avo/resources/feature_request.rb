class Avo::Resources::FeatureRequest < Avo::BaseResource
  self.title = :id
  self.includes = [ :therapist ]

  def fields
    field :id, as: :id
    field :kind, as: :select, options: FeatureRequest::KINDS.index_by(&:itself), enum: nil
    field :status, as: :select, options: FeatureRequest::STATUSES.index_by(&:itself), enum: nil
    field :body, as: :textarea
    field :page_url, as: :text, only_on: :show
    field :therapist, as: :belongs_to
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
