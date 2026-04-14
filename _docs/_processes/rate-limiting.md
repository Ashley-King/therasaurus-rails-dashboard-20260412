# Rate Limiting

Two layers, both backed by `Rails.cache` (Solid Cache in production,
memory_store in development).

## Layer 1 — Rails 8 `rate_limit` (controller)

Tight, user-friendly limits. Fires first in normal traffic and redirects
the user back to the form with a readable flash message.

Configured in [`AuthController`](../../app/controllers/auth_controller.rb):

| Action        | Limit            | Scope           | Why |
|---------------|------------------|-----------------|-----|
| `POST /signin`  | 5 / 15 min       | per IP          | Catches distributed scraping. |
| `POST /signin`  | 5 / 1 hour       | per email       | Catches targeted inbox-flooding. Matches Supabase's own 4/hour OTP limit so we don't get out of sync. |
| `POST /verify`  | 10 / 15 min      | per IP          | Catches OTP brute-force. 6-digit codes mean an attacker needs thousands of tries to be dangerous. |

## Layer 2 — Rack::Attack (middleware)

Looser limits applied before Rails boots the controller. Catches abuse
cheaply and acts as a fallback if a controller-level limit is removed or
misconfigured.

Configured in [`config/initializers/rack_attack.rb`](../../config/initializers/rack_attack.rb):

| Throttle         | Limit             | Scope  | Notes |
|------------------|-------------------|--------|-------|
| `req/ip`         | 300 / 5 min       | per IP | Global safety net across the whole app. |
| `signin/ip`      | 20 / 5 min        | per IP | Outer wall on sign-in. |
| `signin/email`   | 10 / 1 hour       | per email | Outer wall on targeted attacks. |
| `verify/ip`      | 30 / 5 min        | per IP | Outer wall on OTP verification. |

Asset requests and `/up` are safelisted. Localhost is safelisted in
development.

## Response when throttled

- **Rails layer** — redirect back with a flash alert.
- **Rack::Attack layer** — plain `429 Too Many Requests` with `Retry-After`
  header. Logged as `event=rack_attack.throttled`.

## What is NOT rate limited, and why

- **Authenticated dashboard / about-you / your-practice / account-settings
  routes** — low value to an attacker, and the global IP throttle still
  applies. Revisit when the app has more users.
- **`POST /create-account`** — authenticated, one-shot per user.
- **`POST /account-settings/presigned-upload`** — authenticated. Revisit if
  R2 upload abuse ever appears in logs.
- **Stripe webhooks** — not yet built. When added, **do not** rate limit;
  verify the signature and let Stripe retry.
- **Meilisearch** — this Rails app does not expose a search endpoint.
  `search.therasaurus.org` has its own perimeter.

## TODOs for future features

- `POST /account-settings/update-email` (currently stubbed): add a rate
  limit when the send-email flow is implemented.
- Any future contact form or public POST: add a rate limit at both layers.

## Operational notes

- To block an IP in an incident, add it to the `blocklist` block in
  `config/initializers/rack_attack.rb` and deploy.
- Dev throttles can feel aggressive if you test auth repeatedly; localhost
  is safelisted specifically to avoid that. Deploys to staging/prod will
  enforce real limits.
- Throttle events are logged with `event=rack_attack.throttled`; filter
  for that in Better Stack to see abuse patterns.
