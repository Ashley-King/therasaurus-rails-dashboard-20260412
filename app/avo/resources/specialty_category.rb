class Avo::Resources::SpecialtyCategory < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :specialty_to_categories, as: :has_many
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
