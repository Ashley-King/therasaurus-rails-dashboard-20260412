require "base64"
require "digest"
require "securerandom"

class SupabaseAuth
  BASE_URL = Rails.application.credentials.fetch(:SUPABASE_URL)
  API_KEY = Rails.application.credentials.fetch(:SUPABASE_PUBLISHABLE_KEY)
  OAUTH_CODE_CHALLENGE_METHOD = "s256"

  class AuthError < StandardError; end

  def send_otp(email, captcha_token:)
    response = client.post(
      "#{BASE_URL}/auth/v1/otp",
      json: {
        email: email,
        gotrue_meta_security: {
          captcha_token: captcha_token.to_s.strip
        }
      },
      headers: auth_headers
    )

    raise_on_error!(response)

    unless response.status == 200
      body = parse_body(response)
      raise AuthError, body["msg"] || body["error_description"] || "Failed to send OTP"
    end

    true
  end

  def verify_otp(email:, token:)
    response = client.post(
      "#{BASE_URL}/auth/v1/verify",
      json: { email: email, token: token, type: "email" },
      headers: auth_headers
    )

    raise_on_error!(response)

    body = parse_body(response)

    unless response.status == 200
      raise AuthError, body["msg"] || body["error_description"] || "Invalid code"
    end

    body
  end

  def oauth_authorize_url(provider:, redirect_to:, code_challenge:)
    params = {
      provider: provider,
      redirect_to: redirect_to,
      code_challenge: code_challenge,
      code_challenge_method: OAUTH_CODE_CHALLENGE_METHOD
    }

    "#{BASE_URL}/auth/v1/authorize?#{params.to_query}"
  end

  def exchange_code_for_session(auth_code:, code_verifier:)
    response = client.post(
      "#{BASE_URL}/auth/v1/token?grant_type=pkce",
      json: { auth_code: auth_code, code_verifier: code_verifier },
      headers: auth_headers
    )

    raise_on_error!(response)

    body = parse_body(response)

    unless response.status == 200
      raise AuthError, body["msg"] || body["error_description"] || "Could not sign in with Google"
    end

    body
  end

  # Asks Supabase to send an email-change confirmation code to `new_email`.
  # The authenticated user's access token authorizes the request.
  def request_email_change(access_token:, new_email:)
    response = client.put(
      "#{BASE_URL}/auth/v1/user",
      json: { email: new_email },
      headers: auth_headers.merge("Authorization" => "Bearer #{access_token}")
    )

    raise_on_error!(response)

    unless response.status == 200
      body = parse_body(response)
      raise AuthError, body["msg"] || body["error_description"] || "Failed to request email change"
    end

    true
  end

  def verify_email_change(email:, token:)
    response = client.post(
      "#{BASE_URL}/auth/v1/verify",
      json: { email: email, token: token, type: "email_change" },
      headers: auth_headers
    )

    raise_on_error!(response)

    body = parse_body(response)

    unless response.status == 200
      raise AuthError, body["msg"] || body["error_description"] || "Invalid code"
    end

    body
  end

  def refresh_session(refresh_token)
    response = client.post(
      "#{BASE_URL}/auth/v1/token?grant_type=refresh_token",
      json: { refresh_token: refresh_token },
      headers: auth_headers
    )

    raise_on_error!(response)

    body = parse_body(response)

    unless response.status == 200
      raise AuthError, body["msg"] || body["error_description"] || "Failed to refresh session"
    end

    body
  end

  def get_user(access_token)
    response = client.get(
      "#{BASE_URL}/auth/v1/user",
      headers: auth_headers.merge("Authorization" => "Bearer #{access_token}")
    )

    raise_on_error!(response)

    body = parse_body(response)

    unless response.status == 200
      raise AuthError, body["msg"] || "Failed to get user"
    end

    body
  end

  def self.generate_code_verifier
    SecureRandom.urlsafe_base64(32, false)
  end

  def self.code_challenge_for(code_verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end

  private

  def client
    @client ||= HTTPX
  end

  def auth_headers
    {
      "apikey" => API_KEY,
      "Content-Type" => "application/json"
    }
  end

  def raise_on_error!(response)
    return unless response.is_a?(HTTPX::ErrorResponse)

    raise AuthError, "Connection to auth service failed: #{response.error.message}"
  end

  def parse_body(response)
    JSON.parse(response.body.to_s)
  rescue JSON::ParserError
    { "msg" => "Unexpected response" }
  end
end
