class TherapistEducation < ApplicationRecord
  self.table_name = "therapist_education"

  belongs_to :therapist
  belongs_to :college
  belongs_to :degree_type, optional: true
end
