class Language < ApplicationRecord
  has_many :practice_languages
  has_many :therapists, through: :practice_languages
end
