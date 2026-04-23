class TherapistEducation < ApplicationRecord
  self.table_name = "therapist_education"

  YEAR_RANGE = 1940..Date.current.year

  belongs_to :therapist
  belongs_to :college
  belongs_to :degree_type, optional: true

  validates :graduation_year,
            numericality: { only_integer: true, in: YEAR_RANGE },
            allow_nil: true
end
