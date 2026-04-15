# Project Docs Index

## Processes

- [Auth](./_processes/auth.md) — sign-in, OTP verification, session/token handling, sign-out, profile gate
- [Turnstile](./turnstile.md) — captcha setup
- [Business Rules](./business-rules.md) — account + membership rules
- [Background Jobs](./background-jobs.md) — queue list and job responsibilities
- [Logging](./_processes/logging.md) — log shape, filtering rules, Better Stack shipping
- [Rate Limiting](./_processes/rate-limiting.md) — Rails `rate_limit` + Rack::Attack policy
- [Notifications](./_processes/notifications.md) — internal Discord pings + Better Stack error tracking

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
- **Background jobs:** [`background-jobs.md`](./background-jobs.md)
- **Dashboard inspiration screenshots:** [`_frontend/_images/`](./../_frontend/_images/)
  - `desktop/` — Paperbell desktop screenshots (dashboard, settings, email, nav, etc.)
  - `mobile/` — Paperbell mobile screenshots (menu, settings, dashboard)
