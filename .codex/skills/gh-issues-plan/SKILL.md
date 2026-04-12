---
name: gh-issues-plan
description: Create a phased implementation plan for a GitHub issue and save it in `_docs/_issues`. Use this skill when the user asks for a plan for a specific GitHub issue, wants issue research before planning, or wants an issue plan document written to the repo.
---

# GitHub Issue Plan

## Use this skill when

- The user wants a phased plan for a specific GitHub issue.
- The user wants the issue researched before planning.
- The user wants the final plan saved in `_docs/_issues`.

## Goal

- Read the issue, read the code involved, read the project docs involved, read the official docs for the technologies involved, then write a phased implementation plan that is reliable, simple, maintainable, secure, and easy to follow.

## Required workflow

1. Read the GitHub issue first.
   Use the GitHub app or `gh` to read the issue title, body, acceptance details, linked comments, and any implementation hints that affect scope.
2. Read the local code before planning.
   Find the files, tests, routes, jobs, models, controllers, views, services, and docs touched by the issue. Read the current behavior before you suggest changes.
3. Read project docs before planning.
   Start with [`_docs/index.md`](/Users/ashleyking/side-projects/therasaurus-apps-assets/therasaurus-apps/therasaurus-rails/_docs/index.md), then read the docs that match the area touched by the issue.
4. Read the official docs for every technology that matters to the issue.
   Use current primary sources. Do not rely on memory for Rails, Supabase, Postgres, Turbo, Stimulus, Meilisearch, Turnstile, Kamal, or any other technology involved in the issue.
5. Use the create-plan skill before writing the final plan.
   Read [`create-plan`](/Users/ashleyking/.codex/skills/create-plan/SKILL.md) and follow its phase structure and quality bar.
6. Write the plan to the repo.
   Save the final markdown file in `_docs/_issues`.

## File naming rule

- GitHub issue resolution plans must be created in `_docs/_issues`.
- Do not create GitHub issue resolution plans in `_docs/_plans`.
- The file must be named `yyyy-mm-dd-issue-<issue number>-<title slug>.md`.
- Use the current local date for the `yyyy-mm-dd` prefix.
- Use lowercase letters and hyphens in the slug.
- Remove punctuation.
- Example: `2026-04-05-issue-13-simplify-primary-location-lookup-to-one-standard-rails-path.md`

## Plan requirements

- Write in plain English.
- Use phases that can be shipped in order.
- Explain why each phase comes when it does.
- Name the main files or layers likely to change.
- Call out risks, edge cases, validation, and tests.
- Call out temporary inconsistency between phases when it exists.
- Prefer standard Rails and Supabase patterns over custom patterns.
- Keep the plan simple, production ready, secure, and maintainable.
- Include accessibility work when the issue affects user facing behavior.
- Note non standard patterns in the current code when they affect the plan.
- Do not include open questions unless there is a real unknown that changes the plan.
- Do not ask the user questions with an obvious default answer that is already set by this repo.
- Assume standard Rails and Supabase patterns unless the issue clearly requires something else.
- Assume best practices should be followed.
- Do not expand scope to unrelated issues unless they directly affect this issue.

## Output shape

Use this structure unless the user asks for a different format:

1. Goal
2. Assumptions
3. Phase 1
4. Phase 2
5. Phase 3 and later as needed
6. Risks
7. Open questions if needed

For each phase, include:

- Scope
- Why this phase comes now
- Main changes
- Risks or edge cases
- Validation
- Temporary inconsistency, if any

## Done when

- The issue has been read.
- The relevant code has been read.
- The relevant repo docs have been read.
- The official docs for the technologies involved have been checked.
- The plan has been saved to `_docs/_issues/yyyy-mm-dd-issue-<issue number>-<title slug>.md`.
