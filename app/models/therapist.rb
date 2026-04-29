class Therapist < ApplicationRecord
  belongs_to :user
  belongs_to :profession
  belongs_to :country

  has_many :locations, dependent: :destroy
  has_many :therapist_targeted_zips, dependent: :destroy
  has_one :user_credential, dependent: :destroy
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

  has_many :practice_telehealth_platforms, dependent: :destroy
  has_many :telehealth_platforms, through: :practice_telehealth_platforms

  has_many :feature_requests, dependent: :destroy

  has_many :therapist_faqs, -> { order(:created_at) }, dependent: :destroy
  accepts_nested_attributes_for :therapist_faqs, allow_destroy: true, reject_if: :all_blank

  PRACTICE_YEAR_RANGE = 1940..Date.current.year
  BIRTH_YEAR_RANGE = 1940..Date.current.year
  PRACTICE_DESCRIPTION_MAX = 1500
  FAQS_MAX = 5

  validates :year_began_practice,
            numericality: { only_integer: true, in: PRACTICE_YEAR_RANGE },
            allow_nil: true

  validates :time_zone,
            inclusion: { in: ActiveSupport::TimeZone.us_zones.map(&:name) },
            allow_blank: true

  validate :accepting_clients_and_waitlist_exclusion
  validate :practice_description_within_limit
  validate :therapist_faqs_within_limit
  validate :birth_date_within_range

  # Builds the public URL for the profile photo from the R2 object key
  # stored in `practice_image_key`. The URL is never persisted — storing
  # only the key lets us change bucket / CDN / env without a data
  # migration, and keeps the cleanup job's in-use query straightforward.
  def practice_image_url
    return nil if practice_image_key.blank?

    base = Rails.application.credentials.fetch(:R2_PUBLIC_URL).to_s.chomp("/")
    "#{base}/#{practice_image_key}"
  end

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

  # Counts only the visible text length, not the surrounding HTML tags
  # Trix writes (<div>, <strong>, <ul>, etc.), so the user can fill all
  # 1,500 characters with plain prose before hitting the cap.
  def practice_description_within_limit
    return if practice_description.blank?
    plain = ActionView::Base.full_sanitizer.sanitize(practice_description).to_s
    if plain.length > PRACTICE_DESCRIPTION_MAX
      errors.add(:practice_description, "must be #{PRACTICE_DESCRIPTION_MAX} characters or fewer")
    end
  end

  def therapist_faqs_within_limit
    count = therapist_faqs.reject(&:marked_for_destruction?).size
    if count > FAQS_MAX
      errors.add(:base, "You can only add up to #{FAQS_MAX} FAQs.")
    end
  end

  def birth_date_within_range
    return if birth_date.blank?
    unless BIRTH_YEAR_RANGE.cover?(birth_date.year) && birth_date <= Date.current
      errors.add(:birth_date, "must be a real date between #{BIRTH_YEAR_RANGE.first} and today")
    end
  end
end
