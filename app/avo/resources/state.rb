class Avo::Resources::State < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> {
      query.ransack(
        name_cont: params[:q],
        code_cont: params[:q],
        m: "or"
      ).result(distinct: false)
    }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :code, as: :text
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
