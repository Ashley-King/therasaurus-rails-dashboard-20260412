# Rate limiting at the Rack middleware layer.
#
# Runs before Rails boots the controller, so abusive traffic is rejected as
# cheaply as possible. See _docs/_processes/rate-limiting.md for the full
# policy and tuning notes.
#
# Counters live in Rails.cache, which is Solid Cache (database-backed) in
# production and memory_store in development. Both support the atomic
# increment operation Rack::Attack needs.

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  ### Safelists ###

  # Never throttle asset requests or the health check endpoint.
  safelist("allow assets and health check") do |req|
    req.path.start_with?("/assets") || req.path == "/up" || req.path == "/health"
  end

  # Always allow loopback traffic in development so local work is frictionless.
  if Rails.env.development?
    safelist("allow localhost in development") do |req|
      req.ip == "127.0.0.1" || req.ip == "::1"
    end
  end

  ### Blocklist hook ###

  # Empty for now. Add IPs or patterns here when responding to an incident.
  blocklist("block known bad actors") do |_req|
    false
  end

  ### Global throttle ###

  # Broad safety net: any IP hitting the app more than 300 times in 5 minutes
  # is almost certainly a scraper or script.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  ### Auth-specific throttles ###
  #
  # These catch abuse that slips past the global throttle because it is
  # targeted at a specific endpoint. They also back up the Rails controller
  # `rate_limit` calls in AuthController, so a misconfigured controller can't
  # silently remove the protection.

  # POST /signin — by IP. Catches distributed scraping and credential stuffing.
  throttle("signin/ip", limit: 20, period: 5.minutes) do |req|
    req.ip if req.path == "/signin" && req.post?
  end

  # POST /signin — by submitted email. Catches targeted inbox-flooding or
  # lockout attempts against a single user.
  throttle("signin/email", limit: 10, period: 1.hour) do |req|
    next unless req.path == "/signin" && req.post?

    email = req.params["email"].to_s.strip.downcase
    email.presence
  end

  # POST /verify — by IP. Catches OTP brute-force attempts.
  throttle("verify/ip", limit: 30, period: 5.minutes) do |req|
    req.ip if req.path == "/verify" && req.post?
  end

  ### Throttled response ###

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    period = (match_data[:period] || 60).to_i
    name = request.env["rack.attack.matched"]
    ip = request.ip

    Rails.logger.warn(
      "event=rack_attack.throttled " \
      "name=#{name} " \
      "ip=#{ip} " \
      "path=#{request.path}"
    )

    # One Discord ping per IP per hour when they trip any throttle.
    # The cache key doubles as the cooldown. Swallow any errors so
    # the middleware is never blocked by notification plumbing.
    begin
      cooldown_key = "notifier:rack_attack:#{ip}"
      already_notified = Rails.cache.read(cooldown_key)
      unless already_notified
        Rails.cache.write(cooldown_key, true, expires_in: 1.hour)
        Notifier.notify(
          :admin,
          "Rate limit tripped: `#{name}` by `#{ip}` on `#{request.path}` " \
          "(further hits from this IP silenced for 1h)"
        )
      end
    rescue StandardError => e
      Rails.logger.warn("event=rack_attack.notify_failed error=#{e.class}")
    end

    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => period.to_s },
      [ "Too many requests. Please try again later.\n" ]
    ]
  end
end
