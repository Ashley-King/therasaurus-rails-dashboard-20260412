class Avo::Resources::Country < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :code, as: :text
    field :active, as: :boolean
    field :default_locale, as: :text
    field :currency_code, as: :text
    field :postal_code_label, as: :text
    field :administrative_area_label, as: :text
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
