# Project Docs Index

## Processes

- [Auth](./_processes/auth.md) — sign-in, OTP verification, session/token handling, sign-out, profile gate
- [Admin Panel](./_processes/admin-panel.md) — Avo at `/avo`, admin-tools endpoints, resource list
- [Turnstile](./turnstile.md) — CAPTCHA setup for sign-in and public therapist messages
- [Business Rules](./business-rules.md) — account + membership rules
- [Background Jobs](./background-jobs.md) — queue list and job responsibilities
- [Deployment](./_processes/deployment.md) — Kamal, Cloudflare Tunnel, and first deploy checks for `app.therasaurus.org`
- [Billing Lifecycle QA](./_processes/billing-lifecycle-qa.md) — end-to-end billing review checklist
- [Email](./_processes/email.md) — Rails-owned email delivery through Resend SMTP
- [Localization + Country Rules](./_processes/localization.md) — active locale, hidden countries, and country postal-code rules
- [Locations + Geocoding](./_processes/locations.md) — primary/additional locations, targeted postal codes, `Geocodable` concern, ZIP combobox UX
- [Logging](./_processes/logging.md) — log shape, filtering rules, Better Stack shipping
- [Legal Pages](./_processes/legal-pages.md) — public app info, privacy policy, and terms pages
- [Rate Limiting](./_processes/rate-limiting.md) — Rails `rate_limit` + Rack::Attack policy
- [Search](./_processes/search.md) — temporary Meilisearch service and the Supabase-backed public search read table
- [Notifications](./_processes/notifications.md) — internal Discord pings + Better Stack error tracking
- [Stripe](./_processes/stripe.md) — Pay gem integration, billing keys, webhook subscribers, `BillingSync`, idempotency

## Active Plans

- [Cloudflare Rate Limiting + Tunnel Access](./_plans/cloudflare-rate-limiting-and-tunnel-access.md) — Cloudflare Tunnel access, edge rate limits, and abuse monitoring for Rails, Next.js, and the temporary Meilisearch service
- [Google Auth Login](./_plans/google-auth-login.md) — Google sign-in alongside the current Supabase email code flow
- [Localization + Country Foundation](./_plans/localization-country-foundation.md) — backend setup for future translation support and hidden Canada/Mexico preparation
- [Supabase Search Replacement](./_plans/supabase-search-replacement.md) — remove Meilisearch and move public search to the Supabase-backed read table
- [Zero Search Launch Plan](./_plans/zero-search-launch-plan.md) — national launch plan that assumes no search traffic, no ads, free founding therapists first, Rails as the API, and Next.js as the public site

## Folders

- [`_processes/`](./_processes/) — how features work end to end (update as behavior changes)
- [`_plans/`](./_plans/) — active implementation plans
- [`_completed/`](./_completed/) — archived/finished plans
- [`_issues/`](./_issues/) — GitHub issue plans
- [`_background-jobs/`](./_background-jobs/) — per-job notes
- [`_cron-jobs/`](./_cron-jobs/) — scheduled task notes

## Design Reference

- **Design tokens and component styles:** [`_frontend/therasaurus-design/`](./../_frontend/therasaurus-design/)
  - `therasaurus-design-tokens-v2.css` — CSS custom properties and component classes (ts- prefix)
  - `therasaurus-design-tokens-v2.json` — Structured token data for tooling
  - `index.html` — Visual reference of all components
- **Rails favicon:** [`public/icons/icon-dark.svg`](../public/icons/icon-dark.svg)
  and [`public/icons/icon-light.svg`](../public/icons/icon-light.svg) — the
  layout uses color-scheme media queries so light browser tabs get the plum
  mark and dark browser tabs get the white mark.
- **Therapist profile designer field inventory:** [`therapist-profile-design-brief.md`](./therapist-profile-design-brief.md)
- **Background jobs:** [`background-jobs.md`](./background-jobs.md)
- **Dashboard inspiration screenshots:** [`_frontend/_images/`](./../_frontend/_images/)
  - `desktop/` — Paperbell desktop screenshots (dashboard, settings, email, nav, etc.)
  - `mobile/` — Paperbell mobile screenshots (menu, settings, dashboard)
