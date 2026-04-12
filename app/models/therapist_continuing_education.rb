class TherapistContinuingEducation < ApplicationRecord
  self.table_name = "therapist_continuing_education"

  belongs_to :therapist
end
