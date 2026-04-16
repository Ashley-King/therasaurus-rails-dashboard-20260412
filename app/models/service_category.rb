class ServiceCategory < ApplicationRecord
  has_many :service_to_categories, dependent: :destroy
  has_many :services, through: :service_to_categories
end
