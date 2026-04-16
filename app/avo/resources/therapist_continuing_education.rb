class Avo::Resources::TherapistContinuingEducation < Avo::BaseResource
  self.model_class = ::TherapistContinuingEducation

  def fields
    field :id, as: :id
    field :therapist, as: :belongs_to
    field :description, as: :textarea
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
