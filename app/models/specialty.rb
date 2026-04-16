class Specialty < ApplicationRecord
  has_many :practice_specialties
  has_many :therapists, through: :practice_specialties
  has_many :specialty_to_categories, dependent: :destroy
  has_many :specialty_categories, through: :specialty_to_categories

  def category_names
    specialty_categories.pluck(:name).join(", ")
  end
end
