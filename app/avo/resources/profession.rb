class Avo::Resources::Profession < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :slug, as: :text
    field :can_be_supervisor, as: :boolean
    field :profession_type, as: :belongs_to
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
