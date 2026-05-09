# Email

Rails-owned emails are sent through Resend SMTP in development and
production.

## What Rails Sends

- Pay billing emails.
- Trial-ending emails from Pay.
- Payment-failed emails from Pay.
- Plan-change emails from `PlanChangeScheduledMailer`.

Supabase Auth sends sign-in and email-change emails. Rails does not send
those.

## Credentials

Rails reads `RESEND_API_KEY` from encrypted credentials with
`Rails.application.credentials.fetch(:RESEND_API_KEY)`. Missing
credentials fail loudly.

`credentials.example` lists the required key.

## Environment Behavior

Development sends real email by default. This is intentional so billing
and account emails can be tested end to end before deploy.

| Environment | Delivery | Link host |
|---|---|---|
| Development | Resend SMTP | `localhost:3000` |
| Production | Resend SMTP | `https://therasaurus.org` |
| Test | Rails test delivery | `example.com` |

## SMTP Settings

Rails uses Resend SMTP:

- Host: `smtp.resend.com`
- Port: `465`
- Username: `resend`
- Password: `RESEND_API_KEY`
- TLS: on

## Validation

- Send a Rails email in development and confirm it appears in Resend.
- Confirm development email links point to `localhost:3000`.
- Confirm production email links use `https://therasaurus.org`.
- Confirm a missing `RESEND_API_KEY` raises instead of silently skipping
  delivery.
