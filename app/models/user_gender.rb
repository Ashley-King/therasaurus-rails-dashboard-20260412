class UserGender < ApplicationRecord
  belongs_to :therapist
  belongs_to :gender
end
