# Email

Rails-owned emails are sent through Resend SMTP in development and
production.

## What Rails Sends

- Pay billing emails.
- Trial-ending emails from Pay.
- Payment-failed emails from Pay.
- Plan-change emails from `PlanChangeScheduledMailer`.
- Credential reminder and expiration emails from `CredentialReminderMailer`.
- Public profile contact emails from `TherapistMessageMailer`.

Supabase Auth sends sign-in and email-change emails. Rails does not send
those.

## Public Profile Messages

Next.js sends public profile contact form submissions to:

`POST /api/v1/therapists/:unique_id/messages`

The request body is:

```json
{
  "message": {
    "sender_name": "Jane Client",
    "sender_email": "jane@example.com",
    "sender_phone": "555-555-5555",
    "body": "I would like to schedule a consultation.",
    "page_url": "https://therasaurus.org/therapists/example/1234567",
    "turnstile_token": "token-from-cloudflare"
  }
}
```

Rails verifies the Turnstile token with Cloudflare before saving the
message. The therapist's email address is never returned to the browser.

When verification passes, Rails saves a `therapist_messages` row with
`delivery_status = pending`, then enqueues `TherapistMessageDeliveryJob`.
The job sends through Resend SMTP and marks the row `delivered` after
Resend accepts the email. If delivery fails after retries, the row stays
saved with `delivery_status = failed` and can be retried from Avo.
Contact form fields are filtered from request logs.

The mail uses the app sender address and sets `reply_to` to the visitor's
email address.

## Credentials

Rails reads `RESEND_API_KEY` from encrypted credentials with
`Rails.application.credentials.fetch(:RESEND_API_KEY)`. Missing
credentials fail loudly.

Rails reads `TURNSTILE_SECRET_KEY` from encrypted credentials for public
profile message verification.

`credentials.example` lists the required keys.

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
- Submit a public profile message from Next.js and confirm the
  `therapist_messages` row moves from `pending` to `delivered`.
