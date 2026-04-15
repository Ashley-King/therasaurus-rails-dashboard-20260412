# Delivers a Notifier message to a Discord webhook.
#
# Kept deliberately small: one POST, one rescue, one log line on
# failure. We do not retry on Discord errors — a dropped notification
# is not worth a retry storm, and Better Stack will catch any
# exception anyway.
#
# See app/services/notifier.rb for the public API.
class NotifierJob < ApplicationJob
  queue_as :default

  # Discord's per-message content limit.
  MAX_MESSAGE_LENGTH = 2000

  # Don't retry — drop and log. See class comment.
  discard_on StandardError do |job, error|
    Rails.logger.warn(
      "event=notifier.delivery_failed " \
      "channel=#{job.arguments[0]} " \
      "error=#{error.class}"
    )
  end

  def perform(channel, message)
    url = Notifier.webhook_url_for(channel)
    unless url
      Rails.logger.warn("event=notifier.missing_webhook channel=#{channel}")
      return
    end

    body = { content: truncate(message) }

    response = HTTPX.with(timeout: { request_timeout: 5 })
                    .post(url, json: body)

    if response.status >= 400
      Rails.logger.warn(
        "event=notifier.http_error " \
        "channel=#{channel} " \
        "status=#{response.status}"
      )
    end
  end

  private

  def truncate(message)
    return message if message.length <= MAX_MESSAGE_LENGTH

    message[0, MAX_MESSAGE_LENGTH - 3] + "..."
  end
end
