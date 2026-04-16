class Avo::Resources::Service < Avo::BaseResource
  self.title = :name
  self.includes = [ :service_categories ]
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :category_names, as: :text, name: "Categories", only_on: [ :index, :show ]
    field :service_to_categories, as: :has_many
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
