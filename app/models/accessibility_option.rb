class AccessibilityOption < ApplicationRecord
  has_many :practice_accessibility_options
  has_many :therapists, through: :practice_accessibility_options
end
