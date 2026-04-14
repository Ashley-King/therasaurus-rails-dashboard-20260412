# Logging

## Goals

- One JSON line per request so logs are greppable, queryable, and cheap to ship.
- No PII in logs. Ever. Filtered at Rails parameter level, never added back in log subscribers.
- Same log shape in dev and prod so what you debug locally matches what Better Stack shows.
- Debug-level detail in dev, info-level in prod.

## Stack

- **lograge** — collapses Rails' multi-line request logs into a single JSON object per request.
- **logtail-rails** — Better Stack's official gem. Ships logs to Better Stack over HTTPS in a background thread.
- **ActiveSupport::TaggedLogging + BroadcastLogger** — tags every line with the request id and fans out to both STDOUT and Better Stack.

## Log shape

Every request log line is a single JSON object, e.g.:

```json
{
  "method": "POST",
  "path": "/create-account",
  "format": "html",
  "controller": "CreateAccountController",
  "action": "create",
  "status": 302,
  "duration": 184.23,
  "view": 0.0,
  "db": 21.4,
  "time": "2026-04-14T18:22:03.451Z",
  "env": "production",
  "host": "therasaurus.org",
  "request_id": "3f1b...",
  "user_id": 482,
  "params": { "step": "details" }
}
```

Fields:

| Field               | Source                         | Notes                                  |
|---------------------|--------------------------------|----------------------------------------|
| `method`, `path`    | lograge default                |                                        |
| `status`            | lograge default                |                                        |
| `duration`          | lograge default (ms, total)    |                                        |
| `view`, `db`        | lograge default (ms)           |                                        |
| `time`              | custom_options                 | ISO8601 with ms                        |
| `env`               | custom_options                 | `development` / `production`           |
| `host`              | custom_options                 | request host                           |
| `request_id`        | custom_options                 | matches the `[request_id]` tag         |
| `user_id`           | `append_info_to_payload`       | id only — never email                  |
| `params`            | custom_options                 | already filtered by Rails              |
| `exception_class`   | custom_options                 | set on error                           |
| `exception_message` | custom_options                 | truncated to 500 chars                 |

## Log levels

- **Development:** `debug` (override with `RAILS_LOG_LEVEL`)
- **Production:** `info` (override with `RAILS_LOG_LEVEL`)
- **Test:** default Rails — lograge disabled to keep test output clean.

## Filtered parameters

See [`config/initializers/filter_parameter_logging.rb`](../../config/initializers/filter_parameter_logging.rb). Anything added there is filtered from:

- request params logged by Rails / lograge
- ActiveRecord SQL logs
- exception reports

Keep the list conservative — prefer over-filtering over leaking PII. If you add a new PII field to a model, add the column name to this list in the same commit.

## Better Stack shipping

- Configured in [`config/initializers/better_stack.rb`](../../config/initializers/better_stack.rb).
- Enabled in every environment except `test` whenever both credentials are present:
  - `BETTER_STACK_SOURCE_TOKEN`
  - `BETTER_STACK_INGESTING_HOST`
- If either credential is missing, shipping is silently skipped and local STDOUT logging still works. The initializer logs a one-line notice so you know.
- We currently ship from dev too (app isn't deployed yet). Remove dev shipping from the initializer once prod is live if dev noise becomes a problem.
- The HTTP device uses a background queue, so logging a line is non-blocking. If Better Stack is down, lines are dropped rather than blocking requests.

### Setting credentials

```sh
bin/rails credentials:edit
```

Add:

```yaml
BETTER_STACK_SOURCE_TOKEN: <source token from Better Stack>
BETTER_STACK_INGESTING_HOST: s1234567.eu-nbg-2.betterstackdata.com
```

Get both from **Better Stack → Sources → your Rails source → Connect**.

## What NOT to log

- Email addresses
- Phone numbers, addresses, DOBs
- Supabase JWTs, OTP codes, Turnstile tokens
- Request bodies (lograge only logs filtered params, not raw bodies — keep it that way)
- Full IP addresses if we later add them — truncate to `/24` first

## Adding a log line from app code

Use the standard Rails logger — it already broadcasts to Better Stack:

```ruby
Rails.logger.info("geocode.success account_id=#{account.id} status=#{status}")
```

For structured custom events, prefer a short `key=value` style. Do not interpolate email, phone, or other PII into log messages.

## Auth & authz events

The auth flow emits structured `event=auth.*` and `event=authz.*` lines so you can grep Better Stack for any outcome without needing the full request log. All events are PII-free — never email, never OTP codes, never JWTs.

Every event is emitted through a single helper in [`app/controllers/concerns/authentication.rb`](../../app/controllers/concerns/authentication.rb):

```ruby
auth_log(:info, "auth.otp.send_requested", user_id: 42)
```

The helper always includes these fields automatically, so you never have to remember them:

- `event` — the event name
- `ip` — `request.remote_ip` (respects proxy headers — ok for Kamal + Thruster)
- `ua` — user agent, truncated to 200 chars

Any additional keyword arguments are appended as `key=value` pairs. `nil` values are dropped.

### Event list

| Event                                  | Level | Extra fields                                        | Emitted from                                    |
|----------------------------------------|-------|-----------------------------------------------------|-------------------------------------------------|
| `auth.otp.send_requested`              | info  | —                                                   | `AuthController#create`                         |
| `auth.otp.send_result` (ok)            | info  | `result=ok`                                         | `AuthController#create`                         |
| `auth.otp.send_result` (error)         | warn  | `result=error error_class`                          | `AuthController#create`                         |
| `auth.otp.verify_attempted`            | info  | —                                                   | `AuthController#confirm`                        |
| `auth.otp.verify_result` (ok)          | info  | `result=ok user_id`                                 | `AuthController#confirm`                        |
| `auth.otp.verify_result` (error)       | warn  | `result=error error_class`                          | `AuthController#confirm`                        |
| `auth.user.created`                    | info  | `user_id is_admin membership_status`                | `AuthController#find_or_create_user!`           |
| `auth.session.created`                 | info  | `user_id provider=supabase`                         | `AuthController#confirm`                        |
| `auth.profile_gate.redirect`           | info  | `user_id to=create_account`                         | `AuthController#confirm`                        |
| `auth.sign_out`                        | info  | `user_id`                                           | `AuthController#destroy`                        |
| `auth.session.invalid` (jwt_invalid)   | warn  | `reason=jwt_invalid`                                | `Authentication#decode_jwt`                     |
| `auth.session.invalid` (no refresh)    | info  | `reason=jwt_expired_no_refresh`                     | `Authentication#handle_expired_token`           |
| `auth.session.invalid` (refresh fail)  | warn  | `reason=refresh_failed error_class`                 | `Authentication#handle_expired_token`           |
| `auth.session.refreshed`               | info  | `user_id`                                           | `Authentication#handle_expired_token`           |
| `authz.denied` (not signed in)         | info  | `reason=not_signed_in path`                         | `Authentication#require_auth`                   |
| `authz.denied` (incomplete profile)    | info  | `user_id reason=profile_incomplete path`            | `Authentication#require_profile`                |

### Querying

In Better Stack, filter on `message CONTAINS 'event=auth.otp.verify_result result=error'` to see failed verifications, or `event=auth.session.invalid` to see every session tear-down with its reason. Filter on `ip=x.x.x.x` to trace a single actor across the full auth lifecycle.
