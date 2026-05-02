# Deployment + HIPAA Compliance Plan

**Date:** 2026-05-01
**Status:** Draft

## Goal

Deploy the public Therasaurus surface (Next.js frontend + parent↔therapist
contact email path) on AWS in a way that is HIPAA compliant end-to-end,
while keeping the Rails app on its existing non-PHI infrastructure with
Resend for transactional email.

The plan is sized for one developer. No vendors over $100/month. No
compliance automation platforms. Templates and tools used here are all
free and from HHS / NIST / AWS.

## Architecture summary

Two independent surfaces, split by whether they touch PHI:

### PHI path — runs entirely on AWS under the AWS BAA

- **Next.js frontend** — public marketing + therapist directory + parent
  contact form. Deployed to AWS via OpenNext (Lambda + CloudFront + S3).
- **Send-email Lambda** — receives a parent's contact submission,
  sends two emails through SES (one to the therapist, one back to the
  parent as confirmation).
- **Amazon SES** — email delivery for the contact emails. Custom domain,
  DKIM + SPF + DMARC configured.
- **DynamoDB** — stores contact message records (sender, recipient
  therapist, message body, timestamp). Encryption at rest on by default.
- **CloudWatch Logs / Metrics / Alarms** — observability for the PHI
  path. No message bodies in logs.
- **AWS WAF** — Web ACL with managed rule sets in front of CloudFront.
- **AWS GuardDuty + CloudTrail** — account-wide audit + threat detection.

### Non-PHI path — unchanged

- **Rails app** — therapist accounts, therapist profile data, billing,
  admin, **and the search/directory API that Next.js calls**. No
  patient information ever lands here.
- **Supabase Postgres** — Rails' database. Therapist data only.
- **Resend** — transactional email for Rails (account, billing, trial,
  Stripe receipts). Never carries PHI.
- **AppSignal** (or current Rails APM) — Rails-side observability.
  No BAA required because Rails has no PHI; configure standard PII
  filters anyway.

### How the two surfaces talk

- **Next.js → Rails (search + directory reads):** standard HTTPS
  fetches from the Next.js Lambda (or the browser, for non-PHI
  routes) to a public, read-only Rails JSON API. Therapist directory
  data is public, so this carries no PHI.
- **Next.js → AWS (contact form / PHI):** stays entirely inside AWS.
  Rails is never called from this path.
- **AWS → Rails:** never. Rails does not read from DynamoDB or any
  PHI store.

The hard rule: **the parent's contact message body, and any
"who-contacted-whom" record, never crosses from the AWS side into
Rails or Resend.** If the Rails app ever needs to know that a contact
happened (e.g., for analytics), it gets a non-identifying counter only.

**Search queries and PHI:** a parent's search terms ("anxiety
therapist near me") are not PHI on their own — they're directory
queries, like a Google search. They become risky only if Rails logs
them alongside identifying info (IP + session + user identifier).
Mitigation:

- Rails does not log search query strings alongside IP or any
  identifier at request-log granularity. Aggregate counts only.
- The Next.js Lambda calls Rails server-side for search where
  reasonable, so the parent's IP isn't the direct source of the
  Rails-side log line.
- Search responses are public therapist data — safe to cache at
  CloudFront with short TTLs (e.g., 60 seconds) to reduce Rails
  load.

### Talking to Rails from the Next.js Lambda

- Rails exposes a read-only JSON search/directory API at
  `https://<rails-host>/api/v1/search` (or similar — final route
  to be confirmed when wiring up).
- Authentication: a shared API token in an HTTP header, stored in
  AWS Secrets Manager and injected into the Lambda environment.
  Rotate yearly. The token authorizes the Next.js stack as a
  whole, not individual users.
- Rate limiting: Rails already has Rack::Attack — add a generous
  per-token limit so a runaway Lambda loop can't take Rails down.
- Timeout: short (e.g., 3 seconds) on the Next.js side. Render an
  empty-state UI on timeout rather than hanging the page.
- No cookies, no CSRF, no Supabase session — this is a public,
  read-only API.

## Assumptions

- AWS BAA is already signed on the account that will host this stack.
- Resend does **not** sign BAAs on the current plan, so PHI must never
  reach it.
- Vercel is **not** used. Next.js runs on AWS so it sits under the
  existing AWS BAA.
- The Next.js codebase already exists in a sibling repo
  (`therasaurus-next`); this plan covers deployment posture, not
  application code.
- Volume target: ~50,000 visitors/month and ~10,000 contact messages/
  month (= ~20,000 emails/month). Cost estimate at the bottom.
- Solo operator. The "workforce" for HIPAA purposes is one person.

---

## Part 1 — Deployment plan (AWS, PHI path)

### 1.1 AWS account hardening

These are the prerequisites before any PHI hits the account.

| Action | Notes |
|---|---|
| MFA on root user, root access keys deleted | Required by AWS best practice and any honest Risk Analysis. |
| MFA on every IAM user | No console access without MFA. |
| Separate IAM users / roles for deploy vs. day-to-day | No use of root for deploys. |
| CloudTrail enabled, multi-region, log file validation on | Audit log for every API call. Stored in dedicated S3 bucket with object-lock or versioning. |
| GuardDuty enabled in the deploy region | ~$3–10/month at this scale. Catches credential abuse and known-bad traffic. |
| AWS Config recording on (optional but cheap) | Tracks config drift. |
| Default S3 / EBS / DynamoDB / RDS encryption on | Should be on by default in new accounts; verify. |
| Billing alerts | A $X budget alarm so a runaway Lambda loop doesn't surprise you. |

### 1.2 Networking + edge

- Route 53 hosted zone for the public domain.
- ACM certificate (free) for the domain + `www`.
- CloudFront distribution in front of:
  - S3 bucket for static Next.js assets.
  - Lambda function URL (or API Gateway) for SSR.
- AWS WAF Web ACL attached to the CloudFront distribution. Use the
  AWS managed rule sets: Core, Known Bad Inputs, IP reputation, and
  rate-limit rule (~2000 req / 5 min per IP).

### 1.3 Next.js deployment (SST + OpenNext)

- **Deployment tool: SST v3 (Ion).** One TypeScript config, one
  command (`sst deploy`), built on AWS primitives (no lock-in).
  Uses OpenNext under the hood via `sst.aws.Nextjs`.
- Single Lambda function for SSR. 1024 MB memory. 10 second timeout
  initially; tune down once we see real timings.
- Static assets and `_next/static/*` served from S3 via CloudFront.
- Environment variables stored in SST config / Lambda env; secrets
  (Rails API token, etc.) in AWS Secrets Manager, referenced by
  SST.
- **Zero-downtime deploys** come for free: Lambda alias updates are
  atomic (in-flight requests finish on the old version, new requests
  hit the new one), and CloudFront serves immutable hashed assets
  so old pages keep working during the swap.
- Two stages: `staging` and `prod`. Same SST config, different
  stack names.

### 1.4 Contact-form pipeline

```
Parent's browser
  │
  ▼
CloudFront → Lambda (Next.js API route)
                  │
                  ▼
                SQS queue  (SSE-KMS, contact-messages)
                  │  (Lambda event source mapping, batch size 1–10)
                  ▼
                Lambda (send-email handler)
                  │
                  ├──► DynamoDB  (idempotent write of message record)
                  └──► SES       (send 2 emails: therapist + parent confirmation)

                SQS DLQ  (contact-messages-dlq)
                  │  ← messages after maxReceiveCount = 3
                  ▼
                CloudWatch alarm on DLQ depth > 0  → email + Discord
```

**Why SQS from day one:** decouples the form POST from email send,
gives free retries on transient SES errors, absorbs spikes, and the
DLQ catches anything genuinely bad for inspection. SQS is on the AWS
HIPAA-eligible services list (verified against
https://aws.amazon.com/compliance/hipaa-eligible-services-reference/
on 2026-05-01).

**Next.js API route (the producer):**

1. Validates Turnstile.
2. Generates a server-side message UUID.
3. Calls `SQS:SendMessage` with the payload (parent name + email,
   message body, therapist ID, UUID, timestamp).
4. Returns 200 to the browser. Total path is short — no SES,
   DynamoDB, or external network in the request.

**send-email Lambda (the consumer):**

- Triggered by the SQS queue via Lambda event source mapping.
- Batch size: start at 1 (simplest). Increase only if we hit
  throughput problems.
- **Idempotent**: at-least-once delivery is documented behavior, so
  the handler must tolerate duplicates. Strategy:
  - DynamoDB write uses a conditional `PutItem` on the message UUID
    (`attribute_not_exists(pk)`). If the record already exists, the
    handler treats it as already-sent and returns success without
    re-sending email.
- Sends 2 emails via SES (therapist + parent confirmation).
- On exception: throw — SQS will retry per `maxReceiveCount`. After
  3 attempts the message lands on the DLQ.
- Reports per-message failures via `batchItemFailures` if batch
  size > 1.

**Queue configuration:**

| Setting | Value | Reason |
|---|---|---|
| Encryption | **SSE-KMS** with AWS-managed key (`alias/aws/sqs`) | AWS docs explicitly recommend SSE-KMS for compliance-regulated workloads; AWS-managed key is free. |
| Visibility timeout | **60 seconds** | At least 6× the Lambda function timeout (10s) per AWS's general SQS-as-Lambda-source guidance. |
| Lambda function timeout | 10 seconds | Plenty for two SES calls + one DynamoDB write. |
| `maxReceiveCount` | 3 | Three attempts then DLQ. |
| DLQ retention | 14 days | Max retention; gives me time to investigate. |
| Source queue retention | 4 days | Default, fine. |
| Long polling (`ReceiveMessageWaitTimeSeconds`) | 20 seconds | Reduces empty receives. |
| HTTPS + Signature v4 | Required by SQS for SSE-KMS queues. | |

**Idempotency rule (recap):** the message UUID is the DynamoDB
partition key, and the consumer uses `PutItem` with
`attribute_not_exists(pk)`. This is the single source of truth for
"have I already sent email for this submission?" — works whether the
duplicate comes from SQS at-least-once delivery, a Lambda retry, or a
double-click on the form.

### 1.5 SES configuration

- Move the AWS account out of the SES sandbox before launch.
- Custom MAIL FROM domain.
- DKIM (Easy DKIM), SPF (`v=spf1 include:amazonses.com -all`), DMARC.
- Configuration set with **event publishing to CloudWatch** for
  bounces, complaints, and deliveries. No message body or recipient
  email in the metric — just counts.
- Bounce + complaint topic → SNS → Lambda that suppresses bad
  addresses in DynamoDB.
- Sending identity verified for the parent-facing FROM address (e.g.
  `contact@therasaurus.org`).

### 1.6 DynamoDB schema (contact messages)

| Attribute | Type | Notes |
|---|---|---|
| `pk` | S | `MSG#<uuid>` |
| `sk` | S | `META` |
| `therapist_id` | S | foreign key into Rails therapist (just the public ID, not PHI by itself) |
| `parent_email` | S | PHI |
| `parent_name` | S | PHI |
| `message_body` | S | PHI |
| `created_at` | S | ISO8601 |
| `ttl` | N | Optional auto-expire for cold messages (e.g., 2 years) |

- On-demand billing.
- Encryption at rest with AWS-owned key is fine; switch to a
  customer-managed KMS key only if compliance ever asks for it.
- Point-in-time recovery on.
- **No therapist UI for past messages.** Therapists receive each
  contact as an email at the moment it arrives; that email is the
  record they keep. Building a "view past contacts" UI in Rails
  would pull PHI into Rails and force Rails into HIPAA scope, which
  we are explicitly avoiding until revenue justifies it.
- A GSI on `therapist_id` + `created_at` is **deferred** — add it
  only when we build that view. Until then, the table is
  write-only-from-Lambda and read-only-by-me-via-AWS-console for
  debugging.

### 1.7 Logging hygiene (the part that keeps us compliant)

- Lambda functions: never log `parent_email`, `parent_name`, or
  `message_body`. Log the message UUID, the therapist ID, and event
  type (e.g., `contact_form.received`, `ses.send.success`).
- Next.js: same rule for any structured log output.
- CloudWatch log retention: 90 days for app logs, 1 year for SES
  events, 6+ years for CloudTrail (HIPAA recommended retention for
  audit logs).
- Add a unit / integration test that asserts a sample submission
  produces zero log lines containing the test email or body string.

### 1.8 Backups + recovery

- DynamoDB point-in-time recovery on.
- CloudTrail logs in a versioned, MFA-delete-protected S3 bucket.
- Document the restore procedure in this repo. Run it once on a
  staging table. Save the output as evidence.
- Calendar a yearly restore drill.

### 1.9 Observability (AWS-native, no extra vendors)

- **CloudWatch Logs** — all Lambda + SES events.
- **CloudWatch Metrics + Alarms:**
  - Lambda errors > 0 in 5 min
  - SES bounce rate > 5%
  - SES complaint rate > 0.1%
  - WAF blocked count anomaly
- **AWS X-Ray** — tracing across the contact pipeline. First 100k
  traces/month free.
- **CloudWatch RUM** (optional) — page load + JS errors on the
  public site. Skip on the contact-form route to avoid catching PHI
  in form-input replays.

### 1.10 Deployment tooling + CI

- **SST v3 (Ion)** as the single tool. Defines Next.js, DynamoDB,
  SES config, Secrets, IAM, WAF — everything in one TypeScript file.
- GitHub Actions workflow:
  - Lint + typecheck Next.js.
  - `sst deploy --stage staging` on PR.
  - `sst deploy --stage prod` on merge to `main`.
- Deploys assume an AWS role via **GitHub OIDC**, never long-lived
  AWS keys in GitHub secrets.
- Rollback: `sst deploy` again from the previous commit. Lambda
  alias swaps are atomic, so rollback is also zero-downtime.

---

## Part 2 — HIPAA compliance plan (documentation + operations)

The Security Rule requires written policies, retained 6 years. None of
this needs a vendor. All sources below are free and from HHS / NIST.

### 2.1 Tools to use (all free)

| Tool | Purpose | Link |
|---|---|---|
| HHS SRA Tool | Risk Analysis questionnaire + report | https://www.healthit.gov/topic/privacy-security-and-hipaa/security-risk-assessment-tool |
| HHS Security Rule guidance | Sample policies for every required area | https://www.hhs.gov/hipaa/for-professionals/security/guidance/index.html |
| HHS Model Notice of Privacy Practices | Fill-in NPP for the public site | https://www.hhs.gov/hipaa/for-professionals/privacy/guidance/model-notices-privacy-practices/index.html |
| HHS HIPAA training modules | Workforce training (= me) | https://www.hhs.gov/hipaa/for-professionals/training/index.html |
| NIST SP 800-66 Rev. 2 | Implementation guide for the Security Rule | https://csrc.nist.gov/publications/detail/sp/800-66/rev-2/final |

### 2.2 Documents to produce

Stored in a `compliance/` directory in a private repo (not public).
Not in this app's repo if it ever goes open source.

| Document | Source | Notes |
|---|---|---|
| Risk Analysis report | HHS SRA Tool output | The single most-cited HIPAA failure in audits. Do this first. |
| Risk Management Plan | Custom, short | One page: list each risk from the analysis, what we're doing about it, target date. |
| Information Security Policy | HHS template | Master policy, references the others. |
| Access Management Policy | HHS template | Who gets access, how it's granted, how it's revoked. |
| Audit Log Review Procedure | Custom | "Once a month I review CloudTrail anomalies + GuardDuty findings + SES bounce rate." Document the cadence and stick to it. |
| Incident Response Plan | HHS template | Steps for when something goes wrong. Include phone tree of one. |
| Breach Notification Procedure | HHS template | 60-day notification rule, who to call, what to send. |
| Contingency / Disaster Recovery Plan | Custom | Backup approach, restore procedure, RTO/RPO targets. |
| Workstation & Device Security Policy | Custom, short | FileVault on, screen lock on idle, no PHI on local disk, MDM not required at one-person scale but lock screen is. |
| Workforce Sanction Policy | HHS template | Required even when workforce is one person. |
| Designation of Security Officer | Custom, signed | One paragraph. I am the Security Officer. Dated, signed. |
| Designation of Privacy Officer | Custom, signed | Same person, separate document. |
| Workforce Training Records | Custom | Date, training taken, completion screenshot. Repeat annually. |
| Notice of Privacy Practices | HHS Model NPP | Posted publicly on the Next.js site, linked from footer. |
| BAA register | Custom spreadsheet | Vendor, date signed, scope, renewal date. AWS, [Supabase if used for PHI — not in this plan], anyone else. |

### 2.3 Things to actually do (not just write down)

| Action | When |
|---|---|
| Run the HHS SRA Tool end-to-end | Before launch |
| Take HHS HIPAA training, save certificate | Before launch, repeat yearly |
| Sign and file the Security Officer + Privacy Officer designations | Before launch |
| Confirm AWS BAA on file | Before launch |
| Confirm Resend cannot receive PHI by reviewing every Rails mailer | Before launch |
| Publish NPP on the public site | Before launch |
| Run a backup restore drill, save output | Before launch, repeat yearly |
| Calendar: monthly audit log review | Recurring |
| Calendar: quarterly review of IAM users + access | Recurring |
| Calendar: yearly Risk Analysis refresh | Recurring |
| Calendar: yearly policy review | Recurring |

### 2.4 Public-site requirements (Privacy Rule)

- **Notice of Privacy Practices** linked in the footer of every page.
- Contact form copy clearly states: messages are sent to the therapist
  via email. Don't promise confidentiality the email medium can't
  provide.
- Footer link to a "HIPAA & Privacy" page that names the Privacy
  Officer and gives an email address for complaints / individual
  rights requests (access, amendment, accounting of disclosures).

### 2.5 Things we are explicitly NOT doing

- Not paying for Vanta / Drata / Secureframe. Not SOC 2 yet.
- Not paying for Compliancy Group / Accountable HQ. The HHS templates
  are sufficient at this scale.
- Not pursuing HITRUST.
- Not building a customer-managed KMS key strategy until something
  asks for it.
- Not splitting AWS accounts (prod / staging / audit) yet — single
  account with strong IAM and CloudTrail is enough at one developer.
  Revisit if we hire.

---

## Part 3 — Cost estimate

At ~50k visitors/month and ~10k messages/month (= ~20k emails):

| Component | Monthly |
|---|---|
| Next.js on Lambda + CloudFront + S3 | ~$18 |
| SES (20k emails) | ~$2 |
| Lambda (send-email handler) | <$0.10 |
| SQS (source + DLQ, ~30k requests, SSE-KMS w/ AWS-managed key) | <$0.05 |
| DynamoDB (on-demand) | ~$1 |
| CloudWatch Logs + Metrics + X-Ray | ~$10 |
| AWS WAF | ~$12 |
| GuardDuty | ~$5 |
| Route 53 hosted zone | $0.50 |
| **Total** | **~$50/month** |

First 12 months: AWS free tier covers most of Lambda, DynamoDB, and a
chunk of CloudFront — likely **~$15–25/month** in year one.

Compliance documentation: **$0**.

---

## Sequencing

1. **AWS account hardening** (1.1) — one afternoon.
2. **HHS SRA Tool run + draft policy pack** (2.1, 2.2) — one weekend.
3. **Static Next.js deploy** to CloudFront + S3 with WAF in front
   (1.2, 1.3) — one day.
4. **Contact-form pipeline** (1.4–1.6) — two to three days.
5. **Logging hygiene + observability + backups** (1.7–1.9) — one day.
6. **CI/CD via OIDC** (1.10) — half a day.
7. **NPP + footer + HIPAA contact page** (2.4) — half a day.
8. **Sign designations, take training, file evidence** (2.3) — half
   a day.
9. **Move SES out of sandbox + warm sending domain** — runs in
   parallel; start a week before launch.

Total: about two focused weeks of evening/weekend work, plus the SES
warm-up calendar time.

---

## Decisions locked in

- **SQS is in from day one.** SSE-KMS encrypted queue between the
  Next.js API route and the send-email Lambda, with a DLQ and
  CloudWatch alarm. Decouples request from work, gives free retries,
  absorbs spikes.
- **No therapist UI for past messages.** Email is the record. Revisit
  only after Rails is brought into HIPAA scope, which is gated on
  revenue.
- **SST v3 (Ion)** is the deployment tool for Next.js on AWS.
- **Rails is the search/directory API** for Next.js. Public, read-
  only, token-authenticated, no PHI.

## Open questions

- Do we want CloudWatch RUM on the public site at all? It costs
  little but excluding the contact-form route is fiddly. Default:
  skip for now, add only if we need real-user perf data.
- Final route prefix for the Rails search API (`/api/v1/...` vs
  something else) — to be confirmed when the API is wired up.
