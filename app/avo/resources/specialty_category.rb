class Avo::Resources::SpecialtyCategory < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :specialties, as: :has_many, through: :specialty_to_categories
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
