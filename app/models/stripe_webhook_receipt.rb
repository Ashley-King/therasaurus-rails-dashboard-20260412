class StripeWebhookReceipt < ApplicationRecord
  STATUSES = %w[processing completed failed].freeze
  STALE_PROCESSING_AGE = 15.minutes

  validates :stripe_event_id, :event_type, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  def self.run_once_for_event!(event)
    stripe_event_id = event.id.to_s
    event_type = event.type.to_s

    raise ArgumentError, "stripe event id is required" if stripe_event_id.blank?
    raise ArgumentError, "stripe event type is required" if event_type.blank?

    receipt = claim!(stripe_event_id: stripe_event_id, event_type: event_type)
    return false unless receipt

    yield
    receipt.complete!
    true
  rescue StandardError
    receipt&.mark_failed_safely!
    raise
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def recently_processing?
    processing? && updated_at.present? && updated_at > STALE_PROCESSING_AGE.ago
  end

  def complete!
    update!(status: "completed", processed_at: Time.current)
  end

  def mark_failed_safely!
    update!(status: "failed")
  rescue StandardError => error
    Rails.logger.warn(
      "event=stripe_webhook_receipt_status_update_failed " \
      "stripe_event_id=#{stripe_event_id} " \
      "event_type=#{event_type} " \
      "error=#{error.class}"
    )
  end

  def self.claim!(stripe_event_id:, event_type:)
    claimed_receipt = nil

    transaction(requires_new: true) do
      receipt = lock.find_or_initialize_by(
        stripe_event_id: stripe_event_id,
        event_type: event_type
      )

      unless receipt.completed? || receipt.recently_processing?
        receipt.status = "processing"
        receipt.processed_at = nil
        receipt.save!
        claimed_receipt = receipt
      end
    end

    claimed_receipt
  rescue ActiveRecord::RecordNotUnique
    retry
  end
  private_class_method :claim!
end
