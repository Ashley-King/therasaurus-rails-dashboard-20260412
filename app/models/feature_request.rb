class FeatureRequest < ApplicationRecord
  KINDS = %w[specialty service insurance_company college general].freeze
  STATUSES = %w[open reviewed implemented declined].freeze

  belongs_to :therapist

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :body, presence: true, length: { maximum: 2000 }
  validates :page_url, length: { maximum: 1000 }, allow_blank: true
end
