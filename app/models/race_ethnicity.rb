class RaceEthnicity < ApplicationRecord
  has_many :user_race_ethnicities
  has_many :therapists, through: :user_race_ethnicities
end
