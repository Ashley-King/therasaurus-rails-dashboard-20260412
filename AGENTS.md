# Therasaurus Rails Agent Notes
ruby-3.3.11
This is a small app with no users. It has not been deployed. Expect up to 10000 users in the next 5 years. The dev team is me. A single person.

## MAIN GOAL
This app exists to help me make more money so that I can eventually pay for the extended caregiving for my parents and my husband. My husband is 24 years older than me. He's about two years younger than my parents. I am on a mission to make as much money as possible as quickly as possible. Please keep that in mind when you're building this app. I can't waste time here, and I can't spin my wheels on over-engineering this. I need it to be simple, reliable, easily maintainable, production-ready, and secure.

## Main rules
This app must be: simple, reliable, easily maintainable, secure, production-ready. Do not plan for multitenancy or enterprise scale.

Use rails conventions and with no unnecessary abstractions or complexity.
Solve the common case first; handle edge cases only if they are likely.
Supabase auth is used for authentication and authorization. Role based access control is used for authorization. Never rely on the browser for auth decisions.

Read the docs for rails and use the supabase mcp 

Use stripe docs for stripe integration.

call out non-industry-standard patterns in the code and stop code generation until you get my approval.

Development sends real emails by default on purpose. Resend is the transactional email provider.

Make sure rubocop is passing before you commit code.

Do not create fallbacks or legacy compatibility code unless you get my approval. This app is not a legacy system. It is a new system. It is not a migration. It is a rebuild.

Read [`_docs/index.md`](/Users/ashleyking/side-projects/therasaurus-apps-assets/therasaurus-apps/therasaurus-rails/_docs/index.md) before you make changes that depend on project rules, account flows, search behavior, or database reference data.

Update docs and CHANGELOG.md when you make changess.

Turnstile is used for captcha verification. Turn off turbo for turnstile.

Supabase verifies turnstile in the OTP send step. Rails does not verify turnstile in the OTP send step.

Build for one developer to run and maintain.
Make sure this site is accessible so I don't get sued.

# code

Your local shell will not have this ruby/bundler version so you will need to use mise to run the app.

## Code rules
- routes are hyphenated like this: `/dashboard/update-email` not snake_case like this: `dashboard_update_email`
- Prefer normal Rails patterns over custom frameworks.
- Keep files small and names obvious.
- Avoid clever code.
- All buttons and links should have a cursor pointer and focus styles. All buttons and links should be keyboard navigable. All modals should trap focus and be keyboard navigable. 
- Add a new layer only when the simpler option is clearly failing.
- Write code that is easy to trace in one pass.
- All pages should be accessible.
- Do not use Rails.application.credentials.MY_KEY for important secrets. It can return nil. That can hide config mistakes. Prefer Rails.application.credentials.fetch(:KEY_NAME)

## Database and Supabase rules

- Supabase Auth handles identity.
- Rails handles app behavior and app writes.
- Postgres stores app data.
- Keep RLS enabled on exposed tables.
- Use deny by default for RLS.
- Add a policy only when the browser truly needs direct access.
- Do not add broad allow-all policies.
- Keep service keys on the server only.
- Prefer Rails migrations, database constraints, and indexes over database functions and triggers.
- do not create structure.sql files. Do not write tests unless necessary.

## Search rules

- Treat `search.therasaurus.org` as the Meilisearch service for this app.
- Keep normal user saves independent from Meilisearch.
- The meilisearch geocoding index has been moved to supabase
- Use Rails jobs for search writes that happen after user saves.
- Keep search sync safe to run more than once.
- Make indexing jobs safe to run more than once.

## Deployment rules

- Assume Kamal deploys this app to a VPS unless the project says otherwise.

## Change rules

- Prefer small migrations and small code changes.
- Keep security checks close to the code that uses them.
- Add or update tests when behavior changes.
- Update `_docs` process, background jobs, cron jobs files when we create new ones or when existing ones change. 
- medium and large changes to the app and features should be documented in a CHANGELOG.md file using the date format YYYY-MM-DD. Newer changes should be listed first.
  
## Repo skills

- Put repo specific skills in `.codex/skills/<skill-name>/SKILL.md`.
- Keep each skill short, task specific, and easy to scan.
- Put helper files for a skill inside that same skill folder.
