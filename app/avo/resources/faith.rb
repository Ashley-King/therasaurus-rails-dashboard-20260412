class Avo::Resources::Faith < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
