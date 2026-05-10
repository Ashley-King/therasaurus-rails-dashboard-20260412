class TherapistMessageDeliveryJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    message = TherapistMessage.find_by(id: job.arguments.first)
    message&.mark_failed!(error)

    Notifier.notify(
      :email_service,
      "Therapist message delivery failed after retries. " \
      "therapist_message_id=#{message&.id || job.arguments.first} error=#{error.class}"
    )
  end

  discard_on ActiveJob::DeserializationError

  def perform(therapist_message_id)
    message = TherapistMessage.find(therapist_message_id)
    return if message.delivery_delivered?

    message.increment!(:delivery_attempts)
    TherapistMessageMailer.with(message: message).new_message.deliver_now
    message.mark_delivered!
  end
end
