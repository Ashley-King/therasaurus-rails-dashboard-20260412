class Avo::Resources::ServiceToCategory < Avo::BaseResource
  self.title = :id
  self.visible_on_sidebar = false

  def fields
    field :id, as: :id
    field :service, as: :belongs_to
    field :service_category, as: :belongs_to
  end
end
