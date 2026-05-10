class TherapistMessage < ApplicationRecord
  STATUSES = %w[pending delivered failed].freeze
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
  ERROR_MAX = 1000

  belongs_to :therapist

  enum :delivery_status, STATUSES.index_by(&:itself), prefix: :delivery

  before_validation :normalize_fields

  validates :sender_name, presence: true, length: { maximum: 120 },
    format: { without: /[\r\n]/, message: "cannot contain line breaks" }
  validates :sender_email, presence: true, length: { maximum: 254 },
    format: { with: EMAIL_FORMAT }
  validates :sender_phone, length: { maximum: 40 }, allow_blank: true
  validates :body, presence: true, length: { maximum: 2000 }
  validates :page_url, length: { maximum: 1000 }, allow_blank: true
  validates :delivery_status, presence: true, inclusion: { in: STATUSES }
  validates :delivery_attempts,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def enqueue_delivery!
    return false if delivery_delivered?

    update!(delivery_status: "pending", failed_at: nil, last_delivery_error: nil)
    TherapistMessageDeliveryJob.perform_later(id)
    true
  end

  def mark_delivered!
    update!(
      delivery_status: "delivered",
      delivered_at: Time.current,
      failed_at: nil,
      last_delivery_error: nil
    )
  end

  def mark_failed!(error)
    update!(
      delivery_status: "failed",
      failed_at: Time.current,
      last_delivery_error: "#{error.class}: #{error.message}".truncate(ERROR_MAX)
    )
  end

  private

  def normalize_fields
    self.sender_name = sender_name.to_s.squish
    self.sender_email = sender_email.to_s.strip.downcase
    self.sender_phone = sender_phone.to_s.squish.presence
    self.body = body.to_s.strip
    self.page_url = page_url.to_s.strip.presence
  end
end
