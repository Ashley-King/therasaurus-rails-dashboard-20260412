# Cloudflare Rate Limiting + Tunnel Access Plan

**Date:** 2026-05-10
**Status:** Draft

## Goal

Put Cloudflare in front of the public Therasaurus services so bad traffic
is stopped before it reaches the VPS, while keeping the Rails
`Rack::Attack` and Rails controller limits as the final app-side guard.

The deployment goal is simple:

- No public service port is open to the internet.
- Cloudflare Tunnel is the only public path into Docker services.
- Cloudflare catches obvious abuse early.
- Rails still protects auth, email change, and ZIP lookup flows.
- Meilisearch remains protected while it exists, but new search work moves
  toward Supabase-backed search.
- Monitoring shows whether the app is being hammered before users feel it.

## Assumptions

- The current Next.js app is already deployed in Docker behind
  Cloudflare Tunnel.
- Meilisearch is already deployed in Docker behind Cloudflare Tunnel,
  but it is temporary and should be removed when Supabase-backed search
  replaces it.
- Rails will likely be deployed with Kamal in Docker and should use the
  same tunnel-only approach.
- The Rails production hostname is `app.therasaurus.org`, routed through
  Cloudflare Tunnel to the Kamal proxy on `http://localhost:3001`.
- The VPS may still allow SSH, but web traffic should not reach it
  directly.
- Stripe webhooks must not be challenged by Cloudflare. Rails and Pay
  verify Stripe signatures.
- The exact Cloudflare plan is not confirmed. Rule count and supported
  time windows depend on plan level.

## Phase 1: Confirm Current Edge And Origin Shape

### Scope

Create a clear map of what Cloudflare exposes today and what Rails will
expose later.

### Why this phase comes now

Rate limits are easy to misapply when several services share a domain.
The safest first step is to confirm hostnames, routes, and origin paths.

### Main changes

- List current public hostnames:
  - Next.js hostname.
  - Temporary Meilisearch hostname, currently treated as
    `search.therasaurus.org`.
  - Future Rails hostname.
  - Future public search route after Supabase replaces Meilisearch.
- List which Docker service each hostname reaches through Cloudflare
  Tunnel.
- Confirm there are no direct DNS records pointing to the VPS public IP
  for web traffic.
- Confirm the VPS firewall does not allow public inbound HTTP or HTTPS.
- Rails gets its own hostname: `app.therasaurus.org`.

### Risks or edge cases

- If any public DNS record points to the VPS, attackers can bypass
  Cloudflare.
- If Rails shares a hostname with Next.js, rate limit rules must be path
  based.
- While Meilisearch is public, write and admin endpoints need extra
  protection beyond normal search keys.
- After Meilisearch is removed, stale Cloudflare rules and tunnel routes
  can hide the real search path if they are not cleaned up.

### Validation

- Public DNS for each hostname resolves through Cloudflare.
- Direct requests to the VPS IP on ports 80 and 443 fail.
- Existing Next.js and temporary Meilisearch traffic still works through
  the tunnel.

### Temporary inconsistency

None.

## Phase 2: Deploy Rails Behind Cloudflare Tunnel

### Scope

Deploy Rails with Kamal while keeping the Rails web container reachable
only from the local Docker network or localhost.

### Why this phase comes now

The edge rules only matter if all web traffic is forced through
Cloudflare first.

### Main changes

- Add a Cloudflare Tunnel route for the Rails web service.
- Run `cloudflared` as a Docker container on the same host as Rails, or
  reuse the existing tunnel container if it already owns the host routing.
- Route `app.therasaurus.org` to `http://localhost:3001`, which is the
  localhost-only Kamal proxy port for Rails.
- Keep `Rack::Attack` enabled in Rails.
- Keep `/up` and `/health` reachable through Cloudflare for monitoring.
- Keep Stripe webhook paths free from Cloudflare challenges.

### Risks or edge cases

- Kamal's proxy may bind a public port by default if not configured
  carefully.
- A tunnel outage can take the app offline even when Rails is healthy.
- A Cloudflare challenge on a webhook route can break Stripe delivery.

### Validation

- Rails loads through the Cloudflare hostname.
- The VPS public IP does not serve Rails directly.
- `/health` works through Cloudflare.
- A Stripe webhook test reaches Rails without a Cloudflare challenge.
- `request.remote_ip` in Rails reflects the real visitor IP after the
  proxy headers are trusted.

### Temporary inconsistency

During the first deploy, Rails may work locally before the tunnel route
is active. Do not send real users to it until the direct-origin check
passes.

## Phase 3: Add Cloudflare Rules In Log Mode

### Scope

Create Cloudflare rules that log likely abuse without blocking real users
yet.

### Why this phase comes now

Cloudflare recommends validating rate limits with logging before turning
on block or challenge actions.

### Main changes

Add rules in this priority order. Use the highest priority rules your
Cloudflare plan supports.

| Priority | Rule | Starting threshold | First action |
|---:|---|---:|---|
| 1 | Rails auth send code: `POST /signin` | 5 to 10 per minute per IP | Log |
| 2 | Rails auth verify code: `POST /verify` | 10 to 20 per minute per IP | Log |
| 3 | Rails ZIP lookup: `GET /zip-search` | 30 per minute per IP | Log |
| 4 | Rails app-wide, excluding assets, health, and webhooks | 240 per 5 minutes per IP | Log |
| 5 | Temporary Meilisearch public search endpoint | Start from real traffic | Log |
| 6 | Future Supabase-backed public search route | Start from real traffic after it exists | Log |

If the Cloudflare plan only allows one rule, start with the app-wide
rule. If the plan supports only short time windows, use a shorter window
and treat the first week as data gathering.

Suggested exclusions:

- Static assets.
- `/up`.
- `/health`.
- `/pay/webhooks/stripe`.
- Verified bots, when the rule builder supports that field.

For temporary Meilisearch, add separate rules from Rails. Do not reuse
Rails auth limits for search traffic. After Supabase-backed search
replaces Meilisearch, move the search limits to the final public search
route and remove the Meilisearch-specific rules.

### Risks or edge cases

- Good users can reload pages quickly during sign-in trouble.
- Cloudflare counters are not a perfect global count, so some extra
  requests can still reach Rails.
- Search traffic can spike from normal typing if the frontend debounce
  breaks.
- Rate limiting verified bots can hurt search visibility.

### Validation

- Cloudflare Security Events shows matching log-only events.
- Rails does not show a matching spike in `event=rack_attack.throttled`
  during normal usage.
- A manual burst against `/signin` appears in Cloudflare logs.
- A manual burst against `/zip-search` appears in Cloudflare logs.

### Temporary inconsistency

For this phase, Cloudflare logs events that Rails may still allow. That
is expected. Enforcement happens in the next phase.

## Phase 4: Turn On Enforcement Carefully

### Scope

Change proven Cloudflare rules from Log to Managed Challenge or Block.

### Why this phase comes now

By this point there should be enough Cloudflare data to avoid blocking
normal users.

### Main changes

- Keep `POST /verify` stricter than the app-wide rule.
- Prefer Block for clear machine-only abuse.
- Prefer Managed Challenge for broad app traffic.
- Keep Stripe webhooks excluded.
- Keep health checks excluded.
- Keep Rails `Rack::Attack` as the final guard.

Recommended starting actions:

| Rule | Action |
|---|---|
| `POST /signin` burst | Managed Challenge |
| `POST /verify` burst | Block |
| `GET /zip-search` burst | Block |
| App-wide burst | Managed Challenge |
| Temporary Meilisearch search burst | Managed Challenge or Block, based on current traffic |
| Future Supabase-backed search burst | Managed Challenge or Block, based on route behavior |

### Risks or edge cases

- Managed Challenge can still create friction for real users.
- Block rules can hide a real bug if a frontend loop starts hammering an
  endpoint.
- Meilisearch write and admin endpoints should not be reachable with a
  browser key while Meilisearch still exists. If they are reachable, use
  Cloudflare rules to block them publicly and keep the admin key
  server-side only.
- When Meilisearch is removed, remove its tunnel route, Cloudflare rules,
  secrets, and alerts in the same cleanup pass.

### Validation

- Known-good sign-in still works.
- Wrong-code attempts eventually block.
- ZIP autocomplete still works while typing normally.
- Stripe webhook tests still work.
- Cloudflare Security Events show the rule name and action.
- Better Stack does not show a new error spike after enforcement.

### Temporary inconsistency

Cloudflare may block some traffic before Rails can log it. That is good
for load, but it means Cloudflare becomes the first place to check during
an attack.

## Phase 5: Monitoring And Alerts

### Scope

Set up simple monitoring that answers one question quickly: is the app
being pounded right now?

### Why this phase comes now

Blocking rules without alerting can hide important activity. Monitoring
should be in place as enforcement turns on.

### Main changes

Cloudflare checks:

- Review Security Events during launch week.
- Review Security Analytics for top IPs, top paths, countries, and
  mitigated request counts.
- Add a Cloudflare Security Events Alert if the plan supports it.
- Optional later: enable Logpush for HTTP request logs if dashboard
  history is not enough.

Better Stack checks:

- Alert when `event=rack_attack.throttled` spikes.
- Alert when `status=429` spikes.
- Alert when `event=auth.otp.send_result result=error` spikes.
- Alert when `event=auth.otp.verify_result result=error` spikes.
- Alert when 5xx responses spike.
- Keep Better Stack exception alerts enabled.

Rails notifications:

- Keep the current Discord admin ping for `Rack::Attack`.
- Revisit the notification shape only if one attacker creates too much
  noise.

Host checks:

- Track CPU, memory, disk, and Docker container restarts on the VPS.
- Watch Cloudflare Tunnel health.
- Keep `/health` in the external uptime monitor.

### Risks or edge cases

- Too many alerts cause alert fatigue.
- Cloudflare may block traffic before Rails logs it, so Rails logs alone
  can look quiet during a real attack.
- If Logpush is added later, do not send sensitive request data to a
  place that cannot hold it safely.

### Validation

- A test burst creates a Cloudflare event.
- A test Rails-side throttle creates a Better Stack log event and the
  current Discord ping.
- A forced `/health` failure alerts through the external uptime monitor.

### Temporary inconsistency

For a while, Cloudflare alerts and Rails alerts will not describe the
same traffic. That is expected because they sit at different layers.

## Phase 6: Tune After Real Traffic

### Scope

Adjust thresholds after a week or two of real traffic.

### Why this phase comes now

The first thresholds are guesses. Real user behavior should set the long
term limits.

### Main changes

- Compare Cloudflare top-path traffic to Rails request logs.
- Raise limits that catch real users.
- Lower limits that only catch obvious abusive clients.
- Add a specific contact-form rule if the public Next.js contact flow
  accepts user messages.
- Add stricter temporary Meilisearch rules if public search traffic
  starts to crawl the full index before the service is removed.
- Remove Meilisearch rules after Supabase-backed search is live.
- Document final Cloudflare rules in `_docs/_processes/rate-limiting.md`.

### Risks or edge cases

- Normal traffic can look different after launch, press, or SEO indexing.
- A bad frontend deploy can look like abuse.
- Lowering limits too fast can create user support issues.

### Validation

- No normal user path is blocked in Cloudflare Security Events.
- Rails `Rack::Attack` events are rare under normal traffic.
- Health checks stay clean.
- Search and sign-in remain usable on mobile.

### Temporary inconsistency

The rate-limiting process doc will lag until final thresholds are chosen.
This plan is the temporary source of truth until Phase 6 is complete.

## Risks

- Cloudflare plan limits may force simpler rules than this plan lists.
- Any direct public origin path bypasses Cloudflare completely.
- Cloudflare Tunnel becomes a required production dependency.
- Managed Challenge can affect accessibility and real users in ways that
  are not obvious from server logs.
- Stripe, uptime monitors, and server-to-server calls can break if they
  are challenged.
- Meilisearch needs separate attention while it exists because it is not
  Rails and does not share Rails auth rules.
- Supabase-backed search will need its own final limits once the public
  route is known.

## Open Questions

- Which Cloudflare plan is the zone on?
- Final hostnames are `therasaurus.org` for Next.js and
  `app.therasaurus.org` for Rails.
- What route or hostname will replace `search.therasaurus.org` after
  Supabase-backed search is live?
- Rails is on a separate hostname: `app.therasaurus.org`.
- While Meilisearch still exists, is it called directly from browsers, or
  only from Next.js?
- Where should Cloudflare alerts go: email, Discord webhook, or another
  channel?
- Should Cloudflare rules be managed by hand at first, or moved into
  Terraform after the first stable version?

## Official Docs Checked

- Cloudflare Tunnel:
  https://developers.cloudflare.com/tunnel/
- Cloudflare rate limiting rules:
  https://developers.cloudflare.com/waf/rate-limiting-rules/
- Cloudflare rate limit setup guidance:
  https://developers.cloudflare.com/waf/rate-limiting-rules/find-rate-limit/
- Cloudflare Security Events alerts:
  https://developers.cloudflare.com/waf/reference/alerts/
- Cloudflare Logpush:
  https://developers.cloudflare.com/logs/about/
- Supabase full text search:
  https://supabase.com/docs/guides/database/full-text-search
- Supabase row level security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
