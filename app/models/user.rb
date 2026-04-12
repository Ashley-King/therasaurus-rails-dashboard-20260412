class User < ApplicationRecord
  has_one :therapist, dependent: :destroy
end
