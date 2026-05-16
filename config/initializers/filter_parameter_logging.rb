# Be sure to restart your server when you modify this file.

# Parameters (and matching keys in nested hashes / headers) that should never
# appear in logs. Uses partial matching, so `:token` also filters `jwt_token`,
# `access_token`, etc.
#
# Keep this list conservative: prefer over-filtering to leaking PII.
Rails.application.config.filter_parameters += [
  # Auth / secrets
  :passw, :secret, :token, :code, :_key, :crypt, :salt, :certificate,
  :jwt, :authorization, :session, :api_key, :access_token, :refresh_token,

  # Supabase / Turnstile
  :otp, :turnstile, :"cf-turnstile-response",

  # Payments
  :ssn, :cvv, :cvc, :card, :account_number, :routing_number,

  # PII we collect on accounts
  :email, :phone, :dob, :date_of_birth,
  :address, :street, :zip, :postal,

  # Public search
  :order_seed,

  # Public profile messages
  :sender_name, :sender_email, :sender_phone, :body, :page_url
]

# Logtail's Rack middleware logs request and response headers separately from
# Rails params. Filter sensitive headers before they are written locally or
# shipped to Better Stack.
Logtail::Integrations::Rack::HTTPEvents.http_header_filters = [
  :authorization,
  :proxy_authorization,
  :cookie,
  :set_cookie
]
