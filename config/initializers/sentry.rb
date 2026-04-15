# Error tracking via Better Stack, which uses the Sentry SDK with a
# Better Stack DSN. Captures uncaught exceptions from controllers,
# background jobs (SolidQueue via ActiveJob), and anywhere in app
# code, and ships them to Better Stack Error tracking.
#
# Alerts are handled by Better Stack natively — email + their mobile
# app — not Discord. See _docs/_processes/notifications.md for the
# reasoning and the channel split.
#
# Credentials (set via `bin/rails credentials:edit`):
#   BETTER_STACK_ERRORS_DSN – from Better Stack → Error tracking →
#                             your source → Ingest tab → DSN
#
# Disabled in development and test — we don't want local noise
# burning through quota, and test exceptions are already visible in
# the terminal.

return unless Rails.env.production?

dsn = Rails.application.credentials[:BETTER_STACK_ERRORS_DSN].presence

if dsn.blank?
  Rails.logger.info("[sentry] BETTER_STACK_ERRORS_DSN missing — not reporting errors")
  return
end

Sentry.init do |config|
  config.dsn = dsn

  # Only errors. No performance tracing — we can turn it on later if
  # we want it, but it eats quota and we don't need it yet.
  config.traces_sample_rate = 0.0

  # Don't send request bodies, cookies, or user IPs. We already scrub
  # PII out of our logs and we want errors held to the same bar.
  config.send_default_pii = false

  # Respect Rails' filter_parameter_logging so anything we already
  # filter out of logs (passwords, tokens, etc.) stays out of errors
  # too. sentry-rails honours this automatically but we set it
  # explicitly here to make the contract visible.
  config.rails.report_rescued_exceptions = false

  # Tag events with the release so we can correlate to deploys later.
  # Kamal sets this via the standard HEROKU_SLUG_COMMIT shim or we
  # fall back to nothing. Safe to leave unset.
  config.release = ENV["GIT_REVISION"].presence

  config.environment = Rails.env
end
