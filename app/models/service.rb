class Service < ApplicationRecord
  has_many :practice_services
  has_many :therapists, through: :practice_services
end
