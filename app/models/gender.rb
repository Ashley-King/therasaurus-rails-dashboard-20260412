class Gender < ApplicationRecord
  has_many :user_genders
  has_many :therapists, through: :user_genders
end
