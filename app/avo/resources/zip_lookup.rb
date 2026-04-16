class Avo::Resources::ZipLookup < Avo::BaseResource
  self.title = :id
  self.search = {
    query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
