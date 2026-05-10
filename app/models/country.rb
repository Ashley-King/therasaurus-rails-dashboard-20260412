class Country < ApplicationRecord
  has_many :therapists

  US_POSTAL_CODE_PATTERN = /\A\d{5}\z/

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2}\z/ }
  validates :name, presence: true, uniqueness: true
  validates :default_locale, :currency_code, :postal_code_label, :administrative_area_label, presence: true
  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }

  def accepts_postal_code?(postal_code)
    return false unless active?

    normalized = postal_code.to_s.strip.upcase

    case code
    when "US"
      normalized.match?(US_POSTAL_CODE_PATTERN)
    else
      false
    end
  end
end
