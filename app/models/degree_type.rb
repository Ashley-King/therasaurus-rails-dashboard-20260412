class DegreeType < ApplicationRecord
  scope :approved, -> { where(status: "approved") }
end
