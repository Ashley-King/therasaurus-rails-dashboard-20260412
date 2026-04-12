class InsuranceCompany < ApplicationRecord
  has_many :practice_insurance_companies
  has_many :therapists, through: :practice_insurance_companies
end
