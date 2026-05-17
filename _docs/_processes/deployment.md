# Deployment

Rails deploys to the same VPS as the public Next.js app, behind
Cloudflare Tunnel.

## Current target

- Public Rails URL: `https://app.therasaurus.org`
- Public Next.js URL: `https://therasaurus.org`
- Rails origin on the VPS: `http://127.0.0.1:3001`
- Next.js origin on the VPS: `http://127.0.0.1:3000`
- Public search during the transition: `https://search.therasaurus.org`

No public web port should point directly at the VPS. Cloudflare Tunnel is
the only public path into Rails.

## Server shape

The VPS runs:

- The existing Next.js Docker app on local port `3000`.
- The Rails Kamal proxy on local port `3001`.
- The Rails web container behind the Kamal proxy.
- The Rails job container running `bin/jobs`.
- `cloudflared` as a host service or container.
- Rails images pulled from the private GitHub Container Registry package
  `ghcr.io/ashley-king/therasaurus-rails`.

The Rails app uses Supabase Postgres, Resend SMTP, Stripe through Pay,
Cloudflare R2, Better Stack, and Discord webhooks through Rails
credentials. Do not put those secrets in Docker Compose files or shell
history.

Solid Cache, Solid Queue, and Solid Cable use the main Supabase Postgres
database. Their tables live in the normal Rails migrations. Do not point
Solid Cache at a separate `cache` database unless `config/database.yml`
also defines that database.

Runtime secrets live in encrypted Rails credentials. `config/database.yml`
reads `DATABASE_URL` from credentials only. The Docker build mounts
`RAILS_MASTER_KEY` only while precompiling assets so Rails can read those
credentials during the build. Dummy email, Stripe, and Better Stack
values are used only while precompiling assets. Those dummy values are
not used by the deployed container.

## Rails config before first deploy

`config/deploy.yml` should use the real VPS host, a private remote image
registry, and bind the Kamal proxy to localhost only:

```yaml
service: therasaurus_rails
image: ashley-king/therasaurus-rails

servers:
  web:
    - ptd-app
  job:
    hosts:
      - ptd-app
    cmd: bin/jobs

proxy:
  host: app.therasaurus.org
  app_port: 80
  healthcheck:
    path: /up
  run:
    http_port: 3001
    bind_ips:
      - 127.0.0.1

registry:
  server: ghcr.io
  username: Ashley-King
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64
  context: .
  secrets:
    - RAILS_MASTER_KEY

env:
  secret:
    - RAILS_MASTER_KEY

ssh:
  user: mb_pro
```

Use the real SSH alias or IP instead of `ptd-app` if the server uses a
different name. Keep `ssh.user` set to the user from the SSH config for
that host. The current server alias uses `mb_pro`.

`builder.context: .` tells Kamal to build from this checkout. Without it,
Kamal builds from a clean local Git clone and ignores uncommitted files.
That is safer for team deploys, but this app is run by one developer and
first deploy fixes may be tested before commit.

Use GitHub Container Registry instead of Kamal's local registry for this
deployment. Kamal's local registry depends on SSH port forwarding from
the VPS back to the laptop. That forwarding can fail when SSH is routed
through Cloudflare Access. A private remote registry avoids that moving
part.

`config/environments/production.rb` should treat the Cloudflare request as
HTTPS and only allow the production host:

```ruby
config.assume_ssl = true
config.force_ssl = true
config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" || request.path == "/health" } } }

config.action_mailer.default_url_options = { host: "app.therasaurus.org", protocol: "https" }

config.hosts = ["app.therasaurus.org"]
config.host_authorization = { exclude: ->(request) { request.path == "/up" || request.path == "/health" } }
```

## Cloudflare Tunnel route

In the existing tunnel, publish this hostname:

```text
app.therasaurus.org -> http://localhost:3001
```

Do not create an `A` or `AAAA` record for `app.therasaurus.org` that
points to the VPS. The tunnel creates the needed Cloudflare-managed DNS
record.

Keep the existing routes:

```text
therasaurus.org -> http://localhost:3000
search.therasaurus.org -> http://localhost:7700
```

Remove the Meilisearch route when the Supabase-backed search migration is
complete.

## Cloudflare rules

Start rules in log mode for the first deploy. Do not challenge Stripe,
health checks, or static assets.

Recommended Rails rules:

| Route | Starting threshold | First action |
|---|---:|---|
| `POST /signin` | 5 to 10 per minute per IP | Log |
| `POST /verify` | 10 to 20 per minute per IP | Log |
| `GET /zip-search` | 30 per minute per IP | Log |
| `POST /api/v1/search` | 120 per minute per IP | Log |
| App-wide, excluding assets, health, and webhooks | 240 per 5 minutes per IP | Log |

Always exclude:

- `/up`
- `/health`
- `/assets/*`
- `/pay/webhooks/stripe`

After a few days of normal testing, move proven rules from log mode to
block or managed challenge. Prefer block for narrow abuse routes. Prefer
managed challenge for broader app-wide rules.

## Connected services

Update these before using the production URL:

- Supabase Site URL: `https://app.therasaurus.org`
- Supabase redirect URLs:
  - `https://app.therasaurus.org/verify`
  - `https://app.therasaurus.org/signin/google/callback`
- Google OAuth callback:
  - `https://app.therasaurus.org/signin/google/callback`
- Stripe webhook endpoint:
  - `https://app.therasaurus.org/pay/webhooks/stripe`
- Cloudflare Turnstile allowed domain:
  - `app.therasaurus.org`
- R2 bucket CORS allowed origin:
  - `https://app.therasaurus.org`
- Resend domain and sending identity:
  - keep using `therasaurus.org`

## First deploy

Run these from the Rails repo:

```bash
export KAMAL_REGISTRY_PASSWORD=<github personal access token classic with package write/read access>
mise exec -- bin/deploy-production --setup
mise exec -- bin/kamal logs
```

If Docker reports `flag needs an argument: 'p' in -p`, the registry token
was empty in the shell running Kamal. Re-run the export command in that
same terminal before running Kamal again.

If Docker reports `denied: denied` while logging in to `ghcr.io`, the
token is not accepted by GitHub Container Registry. Use a personal access
token classic with `write:packages` and `read:packages`, created by the
same GitHub account used as the registry username.

Use `bin/kamal setup` only for the first deploy or when the server needs
Kamal setup again. Use the production deploy wrapper for normal deploys:

```bash
mise exec -- bin/deploy-production
```

The wrapper runs `bin/ci`, runs Kamal, checks the public app, and runs
`bin/kamal rollback` if the public checks fail. Direct `bin/kamal deploy`
is blocked by `.kamal/hooks/pre-deploy` so the rollback checks are not
skipped by accident.

The public checks request:

- `https://app.therasaurus.org/up`
- `https://app.therasaurus.org/health`
- `https://app.therasaurus.org/signin`
- `https://app.therasaurus.org/create-account`
- `https://app.therasaurus.org/privacy-policy`
- `https://app.therasaurus.org/terms`
- `https://app.therasaurus.org/app-info`
- local CSS, JavaScript, favicon, and manifest files referenced by
  `/signin`

Set `PRODUCTION_APP_URL` only if the public production app URL changes.

## First deploy checks

The production deploy wrapper runs the public HTTP checks above. For the
first deploy, also confirm these from the VPS:

```bash
curl -I http://127.0.0.1:3001/up
docker ps
```

After the first successful deploy, also confirm:

- The VPS public IP does not serve Rails on ports `80` or `443`.
- The job role is running.

Then check the connected services:

- Stripe webhook delivery reaches Rails without a Cloudflare challenge.
- Supabase email code login works at `app.therasaurus.org`.
- Google login returns to `app.therasaurus.org`.
- Profile photo upload gets a presigned R2 URL.
- Credential document upload gets a presigned R2 URL.
- Better Stack receives production logs and errors.

## Rollback

The production deploy wrapper runs rollback automatically when public
checks fail after a deploy:

```bash
mise exec -- bin/deploy-production
```

For a manual emergency rollback, use Kamal rollback:

```bash
mise exec -- bin/kamal rollback
```

A first deploy has no previous working Rails version. Automatic rollback
can only restore a version that already exists on the server.

Keep database changes safe for rollback. Do not deploy a change that
removes or renames a column while the previous app version still needs
that column.

If Cloudflare routing is the issue, remove or pause only the
`app.therasaurus.org` tunnel route. Leave `therasaurus.org` untouched.

## Security notes

`.kamal/secrets` must not contain real secret values if it is committed.
Use shell commands that read secrets locally, or keep real values outside
git. The Rails master key, registry token, database URL, Stripe keys,
Supabase keys, R2 keys, Resend key, Better Stack tokens, and Discord
webhooks are production secrets.

Do not open public inbound HTTP or HTTPS on the VPS for Rails. If a
direct-origin test reaches Rails through the VPS IP, fix the firewall or
Kamal proxy binding before sharing the app URL.

## Official docs checked

- Kamal proxy and deploy config: https://kamal-deploy.org/docs/configuration/proxy/
- Kamal deploy command: https://kamal-deploy.org/docs/commands/deploy/
- Kamal rollback command: https://kamal-deploy.org/docs/commands/rollback/
- Kamal hooks: https://kamal-deploy.org/docs/hooks/overview/
- Rails SSL setting: https://guides.rubyonrails.org/security.html
- Cloudflare Tunnel routing: https://developers.cloudflare.com/tunnel/routing/
- Cloudflare Tunnel service setup: https://developers.cloudflare.com/tunnel/advanced/local-management/as-a-service/
- Cloudflare rate limiting rules: https://developers.cloudflare.com/waf/rate-limiting-rules/
