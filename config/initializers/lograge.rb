# Structured single-line JSON request logs.
#
# Replaces the default multi-line Rails request log with one JSON object per
# request. Easier to read, easier to ship to Better Stack, easier to query.
#
# Development keeps the default Rails logger too (we don't enable lograge in
# dev because the multi-line output is nicer for debugging).

Rails.application.configure do
  config.lograge.enabled = !Rails.env.test?
  config.lograge.keep_original_rails_log = Rails.env.development?

  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.base_controller_class = "ActionController::Base"

  # Silence the healthcheck and asset requests.
  config.lograge.ignore_actions = [ "Rails::HealthController#show" ]
  config.lograge.ignore_custom = lambda do |event|
    event.payload[:path].to_s.start_with?("/assets", "/rails/active_storage")
  end

  # Custom fields added to every request log line.
  # Only non-PII fields — never log email, full IP, or request bodies here.
  config.lograge.custom_options = lambda do |event|
    request = event.payload[:request]
    exception = event.payload[:exception_object]

    {
      time: Time.current.iso8601(3),
      env: Rails.env,
      host: request&.host,
      request_id: request&.request_id,
      user_id: event.payload[:user_id],
      params: event.payload[:params]&.except("controller", "action", "format", "id"),
      exception_class: exception&.class&.name,
      exception_message: exception&.message&.truncate(500)
    }.compact
  end
end
