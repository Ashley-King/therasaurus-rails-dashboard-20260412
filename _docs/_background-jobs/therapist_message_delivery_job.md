# TherapistMessageDeliveryJob

## Purpose

Delivers public profile messages to therapists by email.

## Trigger

`POST /api/v1/therapists/:unique_id/messages` saves a
`therapist_messages` row, then enqueues this job.

A failed message can also be retried from Avo.

## Behavior

1. Loads the saved message.
2. Skips the message if it is already marked `delivered`.
3. Increments `delivery_attempts`.
4. Sends `TherapistMessageMailer#new_message` through Resend SMTP.
5. Marks the message `delivered` after Resend accepts the email.

If all retries fail, the job marks the message `failed` and stores a short
error string in `last_delivery_error`.

## Data safety

The message is saved before the email job runs. A queue failure or SMTP
failure should not lose the lead.

The therapist email address is read server-side from the therapist's user
record. It is never returned to the public API response.
