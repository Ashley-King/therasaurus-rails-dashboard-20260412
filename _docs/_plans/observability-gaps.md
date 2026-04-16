# Observability Gaps Plan

**Date:** 2026-04-15
**Status:** Priority 1 and 2 done. Remaining items deferred until needed.

## Overview

The logging and error tracking stack is production-grade (Better Stack via Sentry SDK, Lograge JSON, structured auth logging, two-layer rate limiting, PII-safe filters). This plan captures the gaps found during the 2026-04-14 audit so they can be addressed incrementally, in priority order.

None of these are blocking. They matter as traffic grows toward the 10k-user target.

---

## Priority 1: External uptime monitoring + real health check

**Why first:** Catches the class of failures in-app logging can't see — deploy broke, DB down, SSL expired, VPS unreachable. Cheap, high value.

### Files to create

| File | Purpose |
|---|---|
| `app/controllers/health_controller.rb` | `/health` endpoint that validates DB connectivity, Supabase reachability, and Solid Queue readiness. Returns JSON with per-dependency status + overall 200/503. Never throttled, silenced from logs. |

### Files to modify

| File | Change |
|---|---|
| `config/routes.rb` | Add `get "health", to: "health#show"`. Keep `/up` as the k8s-style liveness stub. |
| `config/initializers/rack_attack.rb` | Add `/health` to the safelist so uptime pings aren't throttled. |
| `config/initializers/lograge.rb` | Add `/health` to the ignored actions list. |

### External setup (manual, not code)

- Configure UptimeRobot (free) or Checkly to hit `/health` every 1-5 min.
- Alert channel: email + Discord `admin` channel webhook.
- Alert on: 2 consecutive failures (avoid flapping on single blips).

### Verification

- `curl /health` returns `{"db":"ok","supabase":"ok","queue":"ok"}` with 200 when healthy.
- Stopping the DB returns 503 with `"db":"error"` and the specific failure reason.
- `/health` does not appear in production log output.
- External monitor pings successfully and alerts on forced failure.

---

## Priority 2: Alerting fallback when Sentry DSN misconfigures

**Why second:** If `BETTER_STACK_ERRORS_DSN` is missing or rotated-and-forgotten in production, exceptions silently vanish. This is the "observability observability" gap.

### Files to modify

| File | Change |
|---|---|
| `config/initializers/sentry.rb` | On Rails boot in production, log a loud warning if `BETTER_STACK_ERRORS_DSN` credential is missing or empty. Optionally fail boot if `FAIL_BOOT_WITHOUT_ERROR_TRACKING=1` is set. |
| `app/jobs/daily_health_check_job.rb` *(new)* | Daily job that confirms Sentry is wired (e.g., checks `Sentry.initialized?`) and pings the Discord `admin` channel if not. |
| `config/recurring.yml` | Add the daily health check job to Solid Queue recurring schedule. |

### Verification

- Booting production without the DSN logs a `WARN` line on startup.
- Daily health check posts to Discord only when Sentry is not initialized.
- Healthy state produces no Discord noise.

---

## Priority 3: Slow query & N+1 detection in production

**Why third:** Undetected slow queries cascade into user-visible slowness. At 10k users, a single N+1 can take the app down.

### Options to evaluate

1. **ActiveSupport::Notifications subscriber** — subscribe to `sql.active_record`, log any query over a threshold (e.g., 500ms) with the calling location. Lowest footprint, no gem.
2. **`prosopite` gem** — N+1 detector designed for production. Logs N+1 patterns to a configurable sink (Better Stack).
3. **`rack-mini-profiler`** — more for dev, less suited for production.

### Files to create

| File | Purpose |
|---|---|
| `config/initializers/slow_query_logger.rb` | Subscribes to `sql.active_record`, logs any query over `SLOW_QUERY_MS` (default 500ms) as `event=sql.slow` with duration, SQL (filtered), and source location. Production-only. |

### Files to modify

| File | Change |
|---|---|
| `Gemfile` | Add `prosopite` (production + dev groups) if we go that route. |
| `config/environments/production.rb` | Enable Prosopite middleware if added. |

### Verification

- A synthetic slow query (`SELECT pg_sleep(1)`) appears in Better Stack as `event=sql.slow`.
- An intentional N+1 (if Prosopite added) surfaces in logs without crashing the request.
- Normal queries produce no extra log volume.

---

## Priority 4: Background job health visibility

**Why fourth:** Solid Queue exceptions go to Sentry, but there's no dashboard for failure rate, queue depth, or job lag. If `NotifierJob` silently fails, you'd only notice by the absence of Discord pings.

### Files to create

| File | Purpose |
|---|---|
| `app/jobs/queue_stats_job.rb` | Hourly job that logs `event=queue.stats` with counts: pending, in-progress, failed, recurring-missed. Includes per-queue breakdown. |

### Files to modify

| File | Change |
|---|---|
| `config/recurring.yml` | Add `queue_stats_job` on an hourly schedule. |
| `app/services/notifier.rb` | Add optional alert when failed job count exceeds threshold (e.g., >10 failures in past hour). |

### Verification

- Hourly log line shows queue counts in Better Stack.
- Forced job failure triggers a threshold alert after crossing the cap.
- No noise under normal conditions.

---

## Priority 5: Rate-limit surge detector

**Why fifth:** Current per-IP cooldown (1/hour) works for single-attacker scenarios but floods Discord under distributed attacks.

### Files to modify

| File | Change |
|---|---|
| `config/initializers/rack_attack.rb` | Replace per-IP Discord alert with a "surge" detector: count throttles in a rolling 5-min window (Rails cache); if >N unique IPs throttled, send a single summary alert (not one-per-IP). Preserve per-IP log lines. |

### Verification

- Single-attacker throttle still produces one Discord alert per hour (unchanged UX).
- Simulated distributed attack (20 IPs throttled in 5 min) produces exactly one summary alert, not 20.
- Structured log lines continue to record every throttle event.

---

## Priority 6: Runtime PII leak scanner (stretch)

**Why last:** The filter list is thorough today. This is a "future-proofing against future-me" item with low immediate value.

### Options to evaluate

1. **Lograge payload validator** — wrap the lograge formatter to scan the serialized JSON for email regexes, phone regexes, etc. Log (but don't drop) any hit as `event=pii.leaked` so you can find and fix it.
2. **Custom Rails.logger wrapper** — higher-effort; likely too much abstraction for a solo app.

### Decision

Defer until we see evidence of actual leaks. Revisit during the next observability review.

---

## What this plan does NOT include (by design)

- No APM tool (New Relic, Datadog, Skylight) — overkill for current scale, and Better Stack logs already cover the top questions.
- No distributed tracing — single-app Rails doesn't need it.
- No log retention policy change — Better Stack handles retention based on plan.
- No PagerDuty / on-call rotation — solo dev, email + Discord is enough.
- No custom Grafana/Prometheus stack — keep the infrastructure burden low.

---

## Suggested order of execution

1. **This week:** Priority 1 (health check + uptime monitor). Highest value, lowest effort.
2. **Next:** Priority 2 (DSN fallback). Small safety net, cheap to add.
3. **When touching the query layer:** Priority 3 (slow query logger).
4. **When a job silently fails:** Priority 4 (queue stats).
5. **If/when attacked:** Priority 5 (surge detector).
6. **Deferred:** Priority 6 (PII scanner).
