class ServiceToCategory < ApplicationRecord
  belongs_to :service
  belongs_to :service_category
end
