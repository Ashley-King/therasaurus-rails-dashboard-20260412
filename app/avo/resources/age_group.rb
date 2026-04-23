class Avo::Resources::AgeGroup < Avo::BaseResource
  self.title = :name
  self.default_sort_column = :sort_order
  self.default_sort_direction = :asc
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :sort_order, as: :number, sortable: true,
          help: "Lower numbers appear first. Gaps (10, 20, 30...) leave room to insert without renumbering."
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
