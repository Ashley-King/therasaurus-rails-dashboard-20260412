class Faith < ApplicationRecord
  has_many :practice_faiths
  has_many :therapists, through: :practice_faiths
end
