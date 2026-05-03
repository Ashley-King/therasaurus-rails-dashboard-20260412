# TheraSaurus Business Rules

## Main user journey

- The app must not expose a user's email address in the interface after they enter it, except for the signed-in read only email row on `Create Account`.

### 1. A therapist starts on the sign in page

- The app uses one page for both sign in and sign up.
- The therapist enters an email address.
- The therapist completes the captcha.
- The app sends a one-time password to that email.
- The code lasts 15 minutes.
- The therapist gets 3 tries for wrong or expired codes.
- Provider failures and local parse failures do not spend one of those tries.

### 2. The therapist enters the one-time password

- If the email already belongs to an account, the therapist signs in.
- If the email is new, the app starts a new account at this step.
- A new account starts as incomplete.
- After the one-time password is accepted, the therapist is sent to `Create Account` if the account is incomplete.
- The app should set the admin flag right away when the email matches an address in `admin_emails`.

### 3. The app decides where to send the therapist next

- If the therapist is banned, the app signs them out and sends them to the home page.
- If the therapist has not finished account setup, the app sends them to `Create Account`.
- If the therapist already finished account setup and they were sent to sign in from a protected internal page by a `GET` or `HEAD` request, the app sends them back to that page after sign in.
- If the therapist already finished account setup, the app sends them to `Account Settings` (the post-signin landing page).

### 4. The therapist completes the Create Account page

- The therapist must be signed in first.
- The therapist must enter first name.
- The therapist must enter last name.
- The therapist can enter the letters behind their name.
- The therapist must choose a profession from a dropdown list.
- The therapist must enter a primary business address.
- The therapist must enter address line 1.
- The therapist can enter address line 2.
- The therapist must enter city.
- The therapist must choose a state from a dropdown list.
- The therapist must enter a 5 digit ZIP code.
- The therapist must enter a phone number.
- The therapist can enter a phone extension.
- The therapist must choose a country.
- The country select should show `United States` as the preselected option.
- `United States` is the only country option in phase one.
- The page should explain that TheraSaurus only supports therapists in the United States right now.
- The page should tell therapists they can email `countries@therasaurus.org` to request support for another country.
- The `Show street address on profile` checkbox should default to true.
- The `Show phone number on profile` checkbox should default to true.
- All Create Account fields are required except phone extension and address line 2.
- A user must have one primary location.
- The primary location is set during Create Account.
- Saving this form creates or updates the therapist profile record.
- Saving this form also creates or updates the primary location.
- Saving this form marks the local therapist profile as complete.
- Saving this form marks the local app user as complete and sets `account_created_at`.
- Saving this form geocodes the primary location synchronously when the
  ZIP resolves against `zip_lookups`; only unresolved ZIPs flip to
  `pending` and enqueue `GeocodeLocationJob`. See
  [`_processes/locations.md`](./_processes/locations.md).
- After this step, the profile is marked as complete.

### 5. The therapist is sent to the Start Your Trial page

- After Create Account is saved, the app sends the therapist to the
  `Start Your Trial` page (the post-signup interstitial).
- The page tells the therapist their account is almost created.
- The page frames the value prop in plain language: "2 weeks to get
  your profile perfect before your card is charged. Your profile goes
  online as soon as the trial starts."
- The page also makes the no-card path clear: if the therapist skips
  checkout, no card is collected and the app does not store one.
- The page has a primary action that sends the therapist to Stripe
  checkout to add a card and start the 14-day trial.
- The page has a secondary action that lets the therapist skip checkout
  and go straight to `Account Settings`.
- A therapist who already used the free trial sees a "subscribe" page
  instead of a "start trial" page (no second free trial).

### 6. Stripe checkout starts membership

- A first time therapist gets a 14-day free trial.
- The trial only starts after the therapist completes Stripe checkout
  and a card is on file.
- If the therapist skips checkout, no card is collected and no trial
  starts.
- A therapist who already used the free trial does not get another free
  trial; they go straight to a paid subscription at checkout.
- Stripe is the source of truth for trial and paid billing status.
- The app reads Stripe events and turns them into app membership states.

### 6a. After successful Stripe checkout

- Stripe Checkout's `success_url` sends the therapist to an app-owned
  post-checkout landing page (`Trial Started`), not directly to
  `Account Settings`.
- The landing page acknowledges the checkout in plain language ("Your
  trial is being set up — we'll take you to your account in a moment")
  and shows a continue link to `Account Settings`.
- The post-checkout landing page must render correctly even if the
  Stripe webhook has not been processed yet. Stripe waits up to 10
  seconds for the webhook before redirecting, but the app must still
  tolerate the case where the redirect lands before the webhook does.
- The post-checkout landing page does NOT decide membership state from
  URL parameters or the `CHECKOUT_SESSION_ID`. Membership state is only
  set when the Stripe webhook is processed.
- From the landing page the therapist continues to `Account Settings`.
  Once the webhook has flipped them to `trialing_member`,
  `Account Settings` shows the `trialing` notification at the top.
- If the therapist reaches `Account Settings` before the webhook has
  been processed, they should still see the app render normally; the
  trialing notification appears once the webhook lands.
- Stripe's `cancel_url` sends the therapist back to the
  `Start Your Trial` page so they can try again or skip.

### 7. The therapist lands on Account Settings

- `Account Settings` is the signed-in landing page; there is no separate
  dashboard page.
- The top nav shows `Your Account`, `About You`, and `Your Practice`.
- The `Account Settings` sidebar has four sections: `Account`,
  `Update Email`, `Notifications`, `Membership`.
- A `Share` button in the top nav opens a profile-link dropdown for
  copying or previewing the public profile.
- Members, trialing members, and pro members can all use the signed-in
  area; access does not depend on credential verification.
- Profile image, practice description, and credential are helpful but
  not required for the account to exist.
- A therapist who arrives here without an active trial or paid
  subscription sees a notification at the top that invites them to
  start their 14-day free trial.
- A trialing therapist sees a `trialing` notification at the top that
  shows when the trial ends and when the card will be charged.

## Account status

- `active` means the account can sign in and use the app.
- `banned` means the account is blocked right away.
- A banned user is logged out right away.
- A banned user cannot use the signed-in area.
- A banned user cannot sign in again.
- A banned user does not have a public profile.

## Membership states

- `member` means the user is a free user.
- `member` includes users who have never started a trial.
- `member` includes users whose trial ended and did not convert.
- `trialing_member` means the free trial is active.
- `trialing_member` gets the same public profile benefits as `pro_member`.
- `trialing_member` does not get credential verification.
- `pro_member` means paid access is active.
- `pro_member` can submit a credential for review and verification.

## Profile completion

- A therapist cannot use the signed-in area (Account Settings, About You,
  Your Practice) until the Create Account page is complete.
- A therapist cannot start membership until the Create Account page is complete.
- A complete profile means the app has the required account setup data.

## What makes a profile public

A profile is public only when all of these are true:

- The membership state is `trialing_member` or `pro_member`.
- The account status is not `banned`.
- The profile is complete.

If any one of those is not true, the profile is not public.

## Public profile page vs directory search

These are not the same rule.

### Public profile page

- The public profile page uses the public visibility rules above.

### Directory search results

- Directory search only includes profiles that are public.
- Directory search also requires a location with working map coordinates.
- Directory search removes profiles that do not have usable map coordinates.

## Credential rules

- A therapist can have one credential record.
- A therapist can have one credential document.
- A therapist can have one credential expiration date.
- A credential is not required to create an account.
- A credential is not required for a public profile during a free trial.
- A trialing member cannot be verified.
- A therapist can only enter credential review after they become `pro_member`.
- When a therapist first becomes `pro_member`, the credential starts in a pending grace window.
- The current pending grace window is 14 days.
- If the therapist does not upload a credential before that window ends, the status becomes `unverified`.
- If the therapist uploads a credential during that window, the status becomes `pending_review`.
- You review the credential yourself.
- If you approve it, the status becomes `verified`.
- On the first day of the expiration month, the therapist gets an email reminder.
- Seven days before the expiration date, the therapist gets another email reminder.
- If a verified credential expires, it moves into a 7 day grace period the next day.
- The therapist gets an email when the grace period starts.
- If the therapist does not update the credential within that 7 day grace period, the status becomes `unverified`.
- The therapist gets an email when the app marks the credential `unverified`.
- A verified credential shows a trust badge on the profile.

## Billing rules

- Stripe decides whether a subscription is active, trialing, past due, unpaid, canceled, incomplete, or paused.
- The app converts that billing status into an app membership state.
- The app does not let therapists set their own membership state.
- The app does not let therapists set their own Stripe customer ID.
- The app keeps a record of trial start, trial end, trial conversion, and trial expiration dates.
- The app only stores a card on file for therapists who completed
  Stripe checkout. Therapists who skipped checkout have no card on file.
- Stripe sends its standard pre-charge email before the first charge.
- The app also sends its own reminder email shortly before the first
  charge so the therapist hears it from us, not just Stripe.
- The app sends an internal admin notification when a therapist cancels
  and when a therapist reactivates.

## Trial and paid membership rules

- A new Stripe trial makes the therapist `trialing_member`.
- The free trial is 14 days and only starts after the therapist
  completes Stripe checkout.
- A `trialing_member` profile goes public immediately (subject to the
  public visibility rules below).
- A `trialing_member` can cancel any time before the trial ends and
  will not be charged.
- If the trial ends without cancellation, Stripe charges the card on
  file and the therapist becomes `pro_member`.
- Paid active billing makes the therapist `pro_member`.
- If the free trial ends and nothing active replaces it, the therapist becomes `member`.
- If paid access ends and nothing active replaces it, the therapist becomes `member`.
- A therapist who never completed checkout stays a `member` with no
  card on file and no public profile.

## Plan change rules

- Therapists can self-serve plan changes (monthly ↔ yearly) through
  the Stripe Customer Portal.
- All plan changes take effect at the end of the current billing
  period, not immediately. There are no prorations, no instant
  charges, and no refunds for unused time.
- Until the end of the period the therapist keeps their current plan
  and benefits.
- When a plan change is scheduled, the app sends the therapist an
  email confirming what will change and when. (Stripe does not send a
  scheduled-change email by default.)
- When the scheduled change actually takes effect, the app does not
  send a separate email; the next invoice receipt from Stripe carries
  the new amount and that is enough.
- The app does not show or block plan changes inside the app. The
  Customer Portal is the single surface for plan changes.

## Dunning rules

- A failed charge moves the subscription to `past_due` (Stripe).
- A `past_due` therapist's profile stays public through Stripe's
  smart-retry window so a one-off declined charge does not nuke their
  visibility.
- The therapist gets a `past_due` banner in Account Settings and an
  email from the app linking to the customer portal.
- If Stripe's retries succeed, the subscription returns to `active`
  and the banner disappears.
- If Stripe's retries are exhausted, the subscription moves to
  `unpaid`. At that point the public profile is taken down (treat
  `unpaid` and `canceled` as not-public).
- The transition from `past_due` to `unpaid` is Stripe's call, not
  the app's — the app reads the state from `customer.subscription.updated`.

## What happens when membership stops

- The therapist keeps the account.
- The therapist keeps the saved profile data.
- The therapist loses public profile access.
- The therapist can reactivate later.
- Reactivation triggers an internal admin notification.

## Admin rules

- Admin access is separate from membership.
- Admin access should use a separate admin flag.
- Admin email matching uses `admin_emails` only.
- The app should set `is_admin` right away when the email matches `admin_emails`.
- If an admin later changes their email address, they should stay admin.
- Admins with incomplete setup are sent to `Create Account` after sign in.
- Admins with complete setup are sent to `Account Settings` after sign in.
- Admins can still open the `Create Account` page while signed in.
- Admins can still open the signed-in area while signed in even when their own setup is incomplete.
- Admins with complete setup can still open the sign in page while signed in.
- Admins can verify or unverify credentials.
- Admins can reach admin pages (Avo at `/avo` and admin tools under `/admin-tools`).
- Admins can still reach admin tools even when their own therapist setup is incomplete.

## Self-service edit rules

Therapists can edit normal profile content like:

- name
- practice details
- specialties
- services
- locations
- fees
- bio
- contact details
- credential upload
- A therapist has a primary location which is set and geocoded when create account is saved. A therapist can update the primary location. A therapist cannot delete the primary location. A therapist can add/update/delete their additional locations.

Therapists cannot directly edit protected system fields like:

- membership state
- admin flag
- account status (banned/active)
- Stripe customer ID
- trial dates
- profile completion flag
- unique ID
- profile slug
- internal user IDs
- credential verification status

- A therapist cannot edit another therapist's information.
- A therapist cannot edit another therapist's locations.

## Setup guide rules

- The setup guide uses 4 items.
- The only required setup item today is membership.
- Profile image is optional.
- Practice description is optional.
- Credential is optional for account creation.
- The setup guide can show 100 percent complete even though some optional profile details are still missing.

## Route and access rules

- Logged out users who try to open the signed-in area (Account Settings,
  About You, Your Practice), membership, create account, or admin pages
  are sent to sign in.
- Logged in therapists with incomplete setup are sent to create account
  before they can use the signed-in area or membership pages.
- Logged in admins can still use the signed-in area even when their own
  setup is incomplete.
- Logged in therapists with complete setup are sent away from create account.
- A therapist who just completed Create Account is sent to the
  `Start Your Trial` page once. They can take the trial or skip to
  Account Settings; either path counts as having seen the offer.
- The `Start Your Trial` page is reachable later from Account Settings
  (under `Membership`) for any therapist without an active trial or
  subscription.
- Logged in non-admin therapists are sent away from the sign in page.
- Logged in admins with incomplete setup are sent to create account when they first sign in.
- Logged in admins with complete setup can still open the sign in page.
- Logged in admins can still open the create account page.
- Banned users are signed out right away.
- Banned users cannot sign in again.
- Only admins can reach admin pages.

## Signed-in landing page rules

- `Account Settings` is the post-signin landing page; there is no
  separate dashboard page.
- The top nav (`app/views/layouts/dashboard.html.erb`) shows
  `Your Account`, `About You`, and `Your Practice`.
- A `Share` button in the top nav opens a profile-link dropdown for
  copying or previewing the public profile.
- The `Account Settings` sidebar has four sections: `Account`,
  `Update Email`, `Notifications`, `Membership`.
- The `Account` section shows the profile photo and lets the therapist
  upload or replace it.
- The `Membership` section is where the Stripe customer portal action
  belongs (when wired up).
- Body text should never be smaller than 16 px.
- Text sizes should use rem units; 16 px should use `1rem`.
- Form labels render at 1rem minimum.

## Profile preview rules

- A signed in therapist can preview their own profile even when it is not public.
- An admin can preview any therapist profile.
- A preview is not public.
- A preview is not indexed.
- A preview is not searchable.
- A preview should use the same profile layout as the public profile as much as possible.
- Phase one should use a preview route.
- Phase one should not add a self service publish switch.
- Public visibility should still be derived from membership state, account status, and profile completion.

## Billing help rules

- Phase one does not need a separate billing support page.
- The membership area should include short billing help text.
- The membership area should include the Stripe customer portal action.

## Feature requests

- A drop-in `shared/feature_request_link` partial renders a text link
  plus a native `<dialog>` modal. It accepts a `kind:` —
  `specialty`, `service`, `insurance_company`, `college`, or `general` —
  and the helper provides per-kind link text, modal title, lead, and
  placeholder.
- Submissions go through `FeatureRequestsController#create`, which
  saves a `feature_requests` row (`therapist_id`, `kind`, `body`,
  `page_url`, `status` defaulting to `open`) and pings the
  kind-specific Discord channel via `Notifier`.
- Admin triage lives in Avo at `/admin/resources/feature_requests`.
- There is no support request modal or `support_requests` table today.
  Feature requests cover the "user wrote in" surface area.

## Profile editor rules

- Profile data is edited under three top-level areas: `About You`,
  `Your Practice`, and `Account Settings`. Each area has its own
  sidebar.
- The `About You` sidebar has: Identity, Primary Credential,
  Education, Professional Development.
- The `Your Practice` sidebar has: Practice Information, Locations,
  Targeted ZIPs, Availability, Introduction, Clients, Accessibility,
  Fees & Payments, Services, Specialties, Social Media, FAQs.
- The `Account Settings` sidebar has: Account, Update Email,
  Notifications, Membership.
- Each section is its own page with its own form (one page, one form).
  Edits no longer happen in modals.
- Each section saves on its own and shows errors inline.
- `Update Email` uses a dedicated multi-step in-page flow because it
  needs a one-time password.

## Email change rules

- Email change should use a dedicated in page flow.
- The therapist should enter the new email address first.
- The app should send a one time password to the new email address.
- The email change flow should explain what happens next in plain language.
- The flow should show clear errors for wrong code, expired code, and rate limited resend attempts.
- The flow should let the therapist request a new code.
- The flow should show a resend timer.
- The flow should prevent repeated resend attempts until the timer ends.
- The flow should not lose progress from an outside click.

## Professional identity rules

- Profession is required.
- Gender is optional.
- Race is optional.
- Ethnicity is optional.
- Pronouns are optional.
- The therapist can add up to 2 education entries.
- Education is optional.
- The therapist can add up to 3 professional training entries.
- Professional training is optional.
- Years in practice is optional.
- School search should support both lookup and write in entry.
- If the therapist cannot find the school, they can enter the school name themselves.

## Credential entry rules

- A therapist has one primary credential record.
- The credential kinds are state credential, organization or membership credential, and certificate.
- The organization or membership option and the certificate option can share one form path.
- The therapist should provide the issuing organization when that applies.
- The therapist should provide the state when that applies.
- The therapist should provide the credential ID when that applies.
- The therapist should provide an expiration date when one exists.
- The therapist should upload one document up to 10 MB.
- Phase one should require the document when a credential is submitted for review.

## Practice detail rules

- The therapist can set a practice name.
- The therapist can choose to use the practice name as the display name on the public profile.
- The therapist can add a website.
- The therapist can add a phone number extension.
- The therapist can choose whether to show the phone number on the profile.
- The introduction is a rich-text field (Trix editor). The toolbar
  exposes bold, bulleted lists, and numbered lists only — no headings,
  italic, underline, links, quotes, or attachments. Submitted HTML is
  sanitized to `%w[div br strong ul ol li]` on save, so anything else
  (links, headings, scripts) is stripped at the boundary.
- The introduction is capped at 1,500 characters of visible text
  (HTML tags do not count against the limit). The editor shows a live
  count and surfaces a per-field validation error if a submission slips
  past the client-side count.
- The therapist must keep one primary location.
- The therapist can add one additional location in phase one.
- The therapist can remove the additional location.
- The therapist cannot remove the primary location.
- The therapist can choose whether to show the street address on the profile.
- The therapist can choose practice accessibility features.
- The therapist can add an accessibility note.
- The therapist can add social links.
- The therapist can add 0 to 5 profile FAQs.
- Each FAQ should include a question and an answer.
- FAQs should be optional.
- FAQs should use plain text fields. HTML tags submitted in either field are stripped on save.

## Client and availability rules

- Clients and Availability are two separate pages
  (`/your-practice/clients` and `/your-practice/availability`).
- Free introductory phone call defaults to yes.
- Accepting new clients defaults to yes.
- Wait list for new clients and accepting new clients cannot both be true.
- English is always listed on the profile.
- Other languages are optional.
- The therapist can add a note about availability.
- The therapist can add business hours on the Availability page.
- Business hours use one open/close time range per day in 15-minute
  increments. A day has only two states: Open or Closed.
- Closed days are represented by the absence of a `business_hours` row;
  there is no "Closed" column. Save replaces all rows in a transaction.
- The hours editor includes a per-row "Copy down" action that copies a
  day's open / close / closed state to every day below it, plus a
  single "Clear all hours" button that marks every day closed.
- Therapists pick a US time zone (`therapists.time_zone`, IANA name)
  used to label their hours on the public profile.
- Early morning, evening, and weekend availability are separate options.
- In person, virtual, or both should be stored clearly.
- Session formats are a many-to-many: Individual, Group, Family,
  Parent-child.
- Telehealth platforms are a many-to-many backed by the
  `telehealth_platforms` table (Zoom for Healthcare, Doxy.me,
  SimplePractice, TheraPlatform, Google Meet, Presence). A freeform
  `telehealth_platform_other` string captures additions. The telehealth
  section only reveals when "Virtual therapy" is checked.

## Fees and payment rules

- Fees & Payments lives at `/your-practice/fees-payment` as a single
  editable form (session fees, payment methods, insurance, fee notes,
  cancellation policy).
- Fees are optional.
- Session fees are split into evaluation, therapy, group therapy,
  consultation, and late cancellation.
- Payment methods are a multi-select.
- Insurance is a multi-select autocomplete combobox. If the therapist
  can't find a company, they submit it inline; the new row lands on
  `insurance_companies` with `status = "pending"` and
  `submitted_by_therapist_id = therapist.id`. The therapist sees their
  own pending submissions in their search results until an admin
  approves or rejects them.
- The therapist can add a fee note.
- Cancellation policy is a free-text field.

## Services and specialties rules

- Services and Specialties live on two separate pages
  (`/your-practice/services` and `/your-practice/specialties`).
- Both pages use the same filter/search picker pattern: a
  selected-chips area at the top, a category filter-chip bar
  (multi-select OR), text search, and a flat list with each item's
  categories shown as small labels.
- Selection is client-side filtering (via the `services_picker` and
  `specialties_picker` Stimulus controllers); the server assigns
  `therapist.service_ids` / `therapist.specialty_ids` in one shot on
  save.
- The pickers themselves do not accept inline write-ins. If a
  therapist can't find a service or specialty, they submit a feature
  request via the `shared/feature_request_link` partial on each page,
  which routes to the kind-specific Discord channel (`:services` /
  `:specialties`).
- The therapist can mark up to 5 specialties as focus specialties via
  a star toggle on each selected chip.
  - Server-side, `YourPractice::SpecialtiesController#update` caps
    focus at 5, syncs `practice_specialties.is_focus`, and wraps the
    sync in a transaction.
  - Focus chips sort first and render with a gold border and filled
    star; the remaining selected specialties become "other areas of
    expertise".
  - When 5 are starred, the remaining stars grey out with a helper
    message.
  - Focus specialties appear first on the public profile.
  - If all selected specialties are marked as focus, the profile does
    not show an `Other areas of expertise` section.
  - A specialty never appears in both sections.
- Phase one does not need drag and drop ordering.
- Phase one does not enforce a hard cap on the number of services or
  specialties.
- Search ranking can weight focus specialties more heavily than the rest.
- Specialties show as badges on the public profile. Services may also
  show as badges.

## Media rules

- The profile photo is part of phase one.
- Profile photo uploads should use the app's R2 credentials from Rails credentials.
- If R2 upload config is missing, the app should return a clear app error and should not fall back to a developer's local AWS credentials.
- Profile photo uploads should also ignore any local AWS SSO profile token in the developer shell.
- Browser uploads to R2 should have a bucket CORS policy that allows the app origin and the `Content-Type` header for `PUT` requests.
- When a therapist has a profile photo, account avatars in the
  signed-in area should show that photo instead of initials.
- A practice logo can be added later or earlier if the layout needs it.
- A short intro video should start as a link field, not a hosted upload.
- A photo gallery should wait until after phase one.

## Future profile theme rules

- Phase one should not let therapists change profile colors.
- The Next.js profile page should still be built in a way that can accept theme values later.
- Future self service theme changes should start small.
- Background color and button color are the first theme options to consider.
- Theme choices must stay accessible.
- When theme editing is added, the app should validate color contrast before save.

## Future AI editing rules

- Phase one should not depend on chat based profile editing.
- The signed-in area should still be built so chat based editing can be added later.
- A future assistant should use the same save rules as the normal forms.
- A future assistant should not write directly to the database in a special path.
- The app should still validate required fields, limits, and protected fields the same way no matter how the change was submitted.
- A future assistant can help therapists add profile details in plain language instead of filling every field by hand.

## Search sync rules

- The current app concept uses one search document per therapist location.
- Duplicate search data across locations is acceptable.
- When a therapist changes a field that affects public profile content or search content, the app should enqueue one background job after save.
- That job should rebuild the public read model.
