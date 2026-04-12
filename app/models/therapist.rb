class Therapist < ApplicationRecord
  belongs_to :user
  belongs_to :profession
  belongs_to :country

  has_many :locations, dependent: :destroy
  has_many :user_credentials, dependent: :destroy
  has_many :therapist_education, class_name: "TherapistEducation", dependent: :destroy
  has_many :therapist_continuing_education, class_name: "TherapistContinuingEducation", dependent: :destroy

  has_many :practice_specialties, dependent: :destroy
  has_many :specialties, through: :practice_specialties

  has_many :practice_services, dependent: :destroy
  has_many :services, through: :practice_services

  has_many :practice_insurance_companies, dependent: :destroy
  has_many :insurance_companies, through: :practice_insurance_companies

  has_many :practice_payment_methods, dependent: :destroy
  has_many :payment_methods, through: :practice_payment_methods

  has_many :practice_age_groups, dependent: :destroy
  has_many :age_groups, through: :practice_age_groups

  has_many :practice_languages, dependent: :destroy
  has_many :languages, through: :practice_languages

  has_many :practice_faiths, dependent: :destroy
  has_many :faiths, through: :practice_faiths

  has_many :practice_accessibility_options, dependent: :destroy
  has_many :accessibility_options, through: :practice_accessibility_options

  has_many :user_genders, dependent: :destroy
  has_many :genders, through: :user_genders

  has_many :user_race_ethnicities, dependent: :destroy
  has_many :race_ethnicities, through: :user_race_ethnicities

  has_many :business_hours, dependent: :destroy

  has_many :practice_session_formats, dependent: :destroy
  has_many :session_formats, through: :practice_session_formats

  validate :accepting_clients_and_waitlist_exclusion

  def display_name
    if use_practice_name && practice_name.present?
      practice_name
    else
      "#{first_name} #{last_name}"
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def primary_location
    locations.find_by(location_type: "primary")
  end

  private

  def accepting_clients_and_waitlist_exclusion
    if accepting_new_clients? && has_waitlist?
      errors.add(:has_waitlist, "cannot be active while accepting new clients")
    end
  end
end
