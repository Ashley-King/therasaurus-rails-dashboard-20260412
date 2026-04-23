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
- If the therapist already finished account setup, the app sends them to the dashboard.

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
- Saving this form starts the first geocoding job for the profile after local account completion succeeds.
- After this step, the profile is marked as complete.

### 5. The therapist is sent to the dashboard for now

- After Create Account is saved, the app sends the therapist to the dashboard for now.
- The app may later send the therapist straight to checkout instead.

### 6. Stripe checkout starts membership

- A first time therapist gets a free trial.
- The free trial is 30 days right now.
- The free trial length may change later.
- A therapist who already used the free trial does not get another free trial.
- Stripe is the source of truth for trial and paid billing status.
- The app reads Stripe events and turns them into app membership states.

### 7. The therapist lands on the dashboard

- The current dashboard can be a placeholder page during auth testing.
- The current dashboard should show the word `Dashboard`.
- The current dashboard should include a log out button.
- Members can use the dashboard.
- Trialing members can use the dashboard.
- Pro members can use the dashboard.
- The dashboard can be used even when the credential is missing or not verified.
- The dashboard shows setup progress.
- Membership is the only required setup item in the current setup guide.
- Profile image, practice description, and credential are helpful but not required for the account to exist.

## Account status

- `active` means the account can sign in and use the app.
- `banned` means the account is blocked right away.
- A banned user is logged out right away.
- A banned user cannot use the dashboard.
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

- A therapist cannot use the dashboard until the Create Account page is complete.
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

## Trial and paid membership rules

- A new Stripe trial makes the therapist `trialing_member`.
- Paid active billing makes the therapist `pro_member`.
- If the free trial ends and nothing active replaces it, the therapist becomes `member`.
- If paid access ends and nothing active replaces it, the therapist becomes `member`.

## What happens when membership stops

- The therapist keeps the account.
- The therapist keeps the saved profile data.
- The therapist loses public profile access.
- The therapist can reactivate later.

## Admin rules

- Admin access is separate from membership.
- Admin access should use a separate admin flag.
- Admin email matching uses `admin_emails` only.
- The app should set `is_admin` right away when the email matches `admin_emails`.
- If an admin later changes their email address, they should stay admin.
- Admins with incomplete setup are sent to `Create Account` after sign in.
- Admins with complete setup are sent to the dashboard after sign in.
- Admins can still open the `Create Account` page while signed in.
- Admins can still open the dashboard while signed in even when their own setup is incomplete.
- Admins with complete setup can still open the sign in page while signed in.
- Admins can verify or unverify credentials.
- Admins can reach admin pages.
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

- Logged out users who try to open dashboard, membership, create account, or admin pages are sent to sign in.
- Logged in therapists with incomplete setup are sent to create account before they can use the dashboard or membership pages.
- Logged in admins can still use the dashboard even when their own setup is incomplete.
- Logged in therapists with complete setup are sent away from create account.
- Logged in non-admin therapists are sent away from the sign in page.
- Logged in admins with incomplete setup are sent to create account when they first sign in.
- Logged in admins with complete setup can still open the sign in page.
- Logged in admins can still open the create account page.
- Banned users are signed out right away.
- Banned users cannot sign in again.
- Only admins can reach admin pages.

## Dashboard home rules

- The first dashboard page shows the therapist photo area.
- The first dashboard page lets the therapist upload or replace the photo.
- The first dashboard page lets the therapist copy the public profile link when the profile is public.
- The first dashboard page lets the therapist open a profile preview when the profile is not public.
- The first dashboard page can still show a preview link even when the profile is public.
- The first dashboard page lets the therapist open Stripe customer portal to manage membership.
- The first dashboard page lets the therapist open a support modal.
- The first dashboard page should show membership state.
- The first dashboard page should show credential review status.
- The first dashboard page should show whether the profile is public right now.
- The dashboard UI should stay very close to the current dashboard layout and feel.
- Dashboard body text should never be smaller than 16 px.
- Dashboard text sizes should use rem units.
- Dashboard text that is 16 px should use `1rem`.

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
- The support modal can also include a billing help category.

## Support request rules

- The support modal lets the therapist send a message without leaving the dashboard.
- A support request should save to the database.
- A support request should send you an email notification.
- A support request should have a category.
- A support request should have a status so you can track open and closed requests.

## Profile editor rules

- The dashboard should edit profile data in sections.
- The sections are Professional identity, Update email, Primary credential, Practice details, Clients and availability, Fees and payment, and Services and specialties.
- Update email stays separate because it needs a one time password flow.
- Each dashboard section should first show a read only summary of the current values.
- Each dashboard section should have an edit action.
- Each section should save on its own.
- Each section should show errors inside the same modal or panel.
- Most edit forms can open in a modal.
- Small forms should not open in an oversized modal.
- Modals should start at a smaller minimum height and grow with the form content up to a maximum height.
- If a form is tall, the form area should scroll inside the modal.
- Update email should not use a modal.
- Update email should open in the page so it is harder to dismiss by accident.

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
- The introduction is a rich-text field. The editor allows bold,
  italic, bulleted lists, and numbered lists only — no headings,
  links, or underline. Submitted HTML is sanitized to
  `%w[div br strong em ul ol li]` on save.
- The introduction is capped at 1,500 characters of visible text
  (HTML tags do not count against the limit).
- The therapist must keep one primary location.
- The therapist can add one additional location in phase one.
- The therapist can remove the additional location.
- The therapist cannot remove the primary location.
- The therapist can choose whether to show the street address on the profile.
- The therapist can choose practice accessibility features.
- The therapist can add an accessibility note.
- The therapist can add social links.
- The therapist can add 0 to 4 profile FAQs.
- Each FAQ should include a question and an answer.
- FAQs should be optional.
- FAQs should use plain text fields.

## Client and availability rules

- Free introductory phone call defaults to yes.
- Accepting new clients defaults to yes.
- Wait list for new clients and accepting new clients cannot both be true.
- English is always listed on the profile.
- Other languages are optional.
- The therapist can add a note about availability.
- The therapist can add business hours.
- Business hours should be simple to enter.
- Phase one business hours should use one time range per day.
- Phase one business hours should support `Closed`, `By appointment only`, or `Open`.
- The hours editor should let the therapist copy one day's hours to other days.
- The hours editor should let the therapist apply the same hours to weekdays in one step.
- Early morning, evening, and weekend availability are separate options.
- In person, virtual, or both should be stored clearly.

## Fees and payment rules

- Fees are optional.
- Payment methods can use multiple select.
- Insurance entry should support both lookup and write in entry.
- If the therapist cannot find an insurance company, they can enter it themselves.
- The therapist can add a note about fees.

## Services and specialties rules

- Services and specialties should use search plus add.
- Services and specialties should support category filters.
- The form should show search results and selected items in separate areas.
- The form should not rely on one large wall of checkboxes.
- The therapist can add up to 2 write in services.
- The therapist can add up to 2 write in specialties.
- Write in services and write in specialties should be optional.
- Write in items should sit behind a small `Can’t find it? Add your own` action.
- The form should show close matches before allowing a write in item.
- The therapist can mark up to 5 specialties as focus specialties.
- A write in specialty can also be marked as a focus specialty.
- Focus specialties should be chosen from the selected specialties list, not from the full search results list.
- The specialties form should show a simple focus counter.
- Focus specialties should appear first on the public profile.
- If all selected specialties are marked as focus specialties, the profile should not show an `Other areas of expertise` section.
- If the therapist selects more than 5 specialties and marks 5 as focus specialties, the 5 focus specialties should show in the main specialties section.
- Any remaining selected specialties should show only in `Other areas of expertise`.
- A specialty should never appear in both sections.
- Phase one does not need drag and drop ordering.
- Phase one should remove the hard cap of 25 services.
- Phase one should remove the hard cap of 25 specialties.
- The app can still warn the therapist when the list gets too long.
- Search ranking can weight focus specialties more heavily than the rest.
- Specialties should show as badges on the public profile.
- Services may also show as badges on the public profile.

## Media rules

- The profile photo is part of phase one.
- Profile photo uploads should use the app's R2 credentials from Rails credentials.
- If R2 upload config is missing, the app should return a clear app error and should not fall back to a developer's local AWS credentials.
- Profile photo uploads should also ignore any local AWS SSO profile token in the developer shell.
- Browser uploads to R2 should have a bucket CORS policy that allows the app origin and the `Content-Type` header for `PUT` requests.
- When a therapist has a profile photo, dashboard account avatars should show that photo instead of initials.
- A practice logo can be added later or earlier if the dashboard layout needs it.
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
- The dashboard should still be built so chat based editing can be added later.
- A future dashboard assistant should use the same save rules as the normal forms.
- A future dashboard assistant should not write directly to the database in a special path.
- The app should still validate required fields, limits, and protected fields the same way no matter how the change was submitted.
- A future dashboard assistant can help therapists add profile details in plain language instead of filling every field by hand.

## Search sync rules

- The current app concept uses one search document per therapist location.
- Duplicate search data across locations is acceptable.
- When a therapist changes a field that affects public profile content or search content, the app should enqueue one background job after save.
- That job should rebuild the public read model.
