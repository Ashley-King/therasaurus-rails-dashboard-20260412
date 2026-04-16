class Avo::Resources::ZipLookup < Avo::BaseResource
  self.title = :zip
  self.search = {
    query: -> { query.ransack(zip_cont: params[:q], city_cont: params[:q], m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :zip, as: :text, sortable: true
    field :city, as: :text, sortable: true
    field :city_alt, as: :text, hide_on: :index
    field :state_id, as: :text, sortable: true, name: "State"
    field :state_name, as: :text, hide_on: :index
    field :county_name, as: :text, hide_on: :index
    field :city_lat, as: :number, hide_on: :index
    field :city_lng, as: :number, hide_on: :index
    field :zip_lat, as: :number, hide_on: :index
    field :zip_lng, as: :number, hide_on: :index
    field :timezone, as: :text, hide_on: :index
  end
end
