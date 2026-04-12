class AgeGroup < ApplicationRecord
  has_many :practice_age_groups
  has_many :therapists, through: :practice_age_groups
end
