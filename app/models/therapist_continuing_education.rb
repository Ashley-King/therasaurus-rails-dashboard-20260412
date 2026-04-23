class TherapistContinuingEducation < ApplicationRecord
  self.table_name = "therapist_continuing_education"

  YEAR_RANGE = 1940..Date.current.year

  belongs_to :therapist

  DESCRIPTION_MAX_LENGTH = 300

  validates :description, presence: true, length: { maximum: DESCRIPTION_MAX_LENGTH }
  validates :year,
            numericality: { only_integer: true, in: YEAR_RANGE },
            allow_nil: true
end
