class SpecialtyCategory < ApplicationRecord
  has_many :specialty_to_categories, dependent: :destroy
  has_many :specialties, through: :specialty_to_categories
end
