class PracticeInsuranceCompany < ApplicationRecord
  belongs_to :therapist
  belongs_to :insurance_company
end
