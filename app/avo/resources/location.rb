class Avo::Resources::Location < Avo::BaseResource
  self.title = :full_address
  self.search = {
    query: -> {
      query.ransack(
        city_cont: params[:q],
        state_cont: params[:q],
        zip_cont: params[:q],
        m: "or"
      ).result(distinct: false)
    }
  }

  def fields
    field :id, as: :id
    field :therapist, as: :belongs_to
    field :location_type, as: :select, enum: ::Location.location_types
    field :street_address, as: :text
    field :street_address2, as: :text
    field :city, as: :text
    field :state, as: :text
    field :zip, as: :text
    field :show_street_address, as: :boolean
    field :latitude, as: :number
    field :longitude, as: :number
    field :canonical_city, as: :text
    field :canonical_state, as: :text
    field :geocode_status, as: :text
    field :geocoded_at, as: :date_time
    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
