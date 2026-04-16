class Avo::Resources::TherapistEducation < Avo::BaseResource
  self.model_class = ::TherapistEducation

  def fields
    field :id, as: :id
    field :therapist, as: :belongs_to
    field :college, as: :belongs_to
    field :degree_type, as: :belongs_to
    field :graduation_year, as: :number
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
