# Ship logs to Better Stack via the logtail-rails gem.
#
# In every environment except :test, if both credentials are present we add a
# second logger that broadcasts to Better Stack alongside the existing STDOUT
# logger. Local STDOUT logging always stays on so we can tail in dev and
# `kamal app logs` in prod.
#
# Credentials (set via `bin/rails credentials:edit`):
#   BETTER_STACK_SOURCE_TOKEN     – from Better Stack → Sources → your source
#   BETTER_STACK_INGESTING_HOST   – e.g. s1234567.eu-nbg-2.betterstackdata.com

return if Rails.env.test?

source_token = Rails.application.credentials[:BETTER_STACK_SOURCE_TOKEN].presence
ingesting_host = Rails.application.credentials[:BETTER_STACK_INGESTING_HOST].presence

if source_token.blank? || ingesting_host.blank?
  Rails.logger.info("[better_stack] source token or ingesting host missing — not shipping logs")
  return
end

Rails.application.config.after_initialize do
  http_device = Logtail::LogDevices::HTTP.new(source_token, ingesting_host: ingesting_host)

  better_stack_logger = Logtail::Logger.new(http_device)
  better_stack_logger.level = Rails.logger.level

  Rails.logger.broadcast_to(better_stack_logger)
end
