class Service < ApplicationRecord
  has_many :practice_services
  has_many :therapists, through: :practice_services
  has_many :service_to_categories, dependent: :destroy
  has_many :service_categories, through: :service_to_categories
end
