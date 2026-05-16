class TurnstileVerifier
  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  class VerificationError < StandardError; end
  class ConfigurationError < StandardError; end

  def self.verify!(token:, remote_ip:)
    new(token: token, remote_ip: remote_ip).verify!
  end

  def initialize(token:, remote_ip:)
    @token = token.to_s
    @remote_ip = remote_ip.to_s.presence
  end

  def verify!
    raise VerificationError, "Turnstile token is required" if @token.blank?

    response = HTTPX.with(timeout: { request_timeout: 5 }).post(
      SITEVERIFY_URL,
      form: form_payload
    )

    raise VerificationError, "Turnstile verification failed" unless response.status == 200

    body = JSON.parse(response.body.to_s)
    return true if body["success"] == true

    raise VerificationError, "Turnstile verification failed"
  rescue KeyError => e
    raise ConfigurationError, e.message
  rescue JSON::ParserError
    raise VerificationError, "Turnstile verification failed"
  end

  private

  def form_payload
    payload = {
      secret: Rails.application.credentials.fetch(:TURNSTILE_SECRET_KEY),
      response: @token
    }
    payload[:remoteip] = @remote_ip if @remote_ip.present?
    payload
  end
end
