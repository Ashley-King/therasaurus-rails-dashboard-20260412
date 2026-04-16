class SpecialtyToCategory < ApplicationRecord
  belongs_to :specialty
  belongs_to :specialty_category
end
