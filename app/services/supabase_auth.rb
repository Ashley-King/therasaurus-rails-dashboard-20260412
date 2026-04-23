class SupabaseAuth
  BASE_URL = Rails.application.credentials.fetch(:SUPABASE_URL)
  API_KEY = Rails.application.credentials.fetch(:SUPABASE_PUBLISHABLE_KEY)

  class AuthError < StandardError; end

  def send_otp(email)
    response = client.post(
      "#{BASE_URL}/auth/v1/otp",
      json: { email: email },
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
