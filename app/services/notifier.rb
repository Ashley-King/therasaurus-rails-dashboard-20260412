# Sends internal-only notifications to Discord via webhooks.
#
# This is for *intentional* domain events we want to know about (new
# signup, user write-ins, etc.), not uncaught exceptions. Exception
# tracking is handled by Better Stack and is configured outside this
# service — see _docs/_processes/notifications.md.
#
# Usage:
#   Notifier.notify(:admin, "New signup: therapist ##{t.id}")
#   Notifier.notify(:college_write_in, "User submitted '#{name}'")
#
# Delivery is always async via NotifierJob so a slow or broken Discord
# webhook can never block a request.
class Notifier
  # Channel symbol → credential key in Rails.application.credentials.
  # Single source of truth for which channels exist. Adding a channel
  # means adding a row here *and* the matching credential.
  CHANNELS = {
    admin: :ADMIN_WEBHOOK,
    errors: :ERRORS_WEBHOOK,
    stripe_errors: :CLOUDFLARE_STRIPE_ERRORS_WEBHOOK,
    college_write_in: :COLLEGE_WRITE_IN_WEBHOOK,
    feature_requests: :FEATURE_REQUESTS_WEBHOOK,
    email_service: :EMAIL_SERVICE_WEBHOOK,
    geocoding: :GEOCODING_WEBHOOK,
    insurance_write_in: :INSURANCE_WRITE_IN_WEBHOOK,
    search_index_service: :SEARCH_INDEX_SERVICE_WEBHOOK,
    supabase: :SUPABASE_WEBHOOK,
    payment_methods: :PAYMENT_METHODS_WEBHOOK,
    services: :SERVICES_WEBHOOK,
    specialties: :SPECIALTIES_WEBHOOK
  }.freeze

  class UnknownChannel < StandardError; end

  # Enqueue a notification for delivery.
  #
  # channel - one of the CHANNELS keys (symbol)
  # message - string, <= 2000 chars (Discord hard limit); longer is truncated
  def self.notify(channel, message)
    raise UnknownChannel, "unknown channel: #{channel.inspect}" unless CHANNELS.key?(channel)

    NotifierJob.perform_later(channel.to_s, message.to_s)
  end

  # Resolve a channel symbol to its webhook URL, or nil if the
  # credential is missing. Kept here (not in the job) so tests and
  # callers can check availability without enqueueing.
  def self.webhook_url_for(channel)
    key = CHANNELS[channel.to_sym]
    return nil unless key

    Rails.application.credentials[key].presence
  end
end
