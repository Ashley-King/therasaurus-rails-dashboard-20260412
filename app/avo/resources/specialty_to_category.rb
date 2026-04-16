class Avo::Resources::SpecialtyToCategory < Avo::BaseResource
  self.title = :id
  self.visible_on_sidebar = false

  def fields
    field :id, as: :id
    field :specialty, as: :belongs_to
    field :specialty_category, as: :belongs_to
  end
end
