class Profession < ApplicationRecord
  belongs_to :profession_type, optional: true
  has_many :therapists
end
