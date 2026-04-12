class Specialty < ApplicationRecord
  has_many :practice_specialties
  has_many :therapists, through: :practice_specialties
end
