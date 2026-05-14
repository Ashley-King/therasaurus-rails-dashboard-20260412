# Zero Search Launch Plan

## Project paths

- Rails app and future API: `/Users/ashleyking/side-projects/therasaurus-apps-assets/therasaurus-apps/therasaurus-rails`
- Public Next.js site: `/Users/ashleyking/side-projects/therasaurus-apps-assets/therasaurus-apps/therasaurus`

## Goal

Support a national launch that does not depend on Google, paid ads, or social media traffic.

The Rails app should give the public site enough data and actions to make empty areas useful, help therapists share their profiles, and collect direct demand from parents and partners.

## Main assumption

The public site will launch nationally even if many areas have no therapists yet.

The Rails app must support that by saving useful signals from parents, free founding therapists, and referral partners.

## What each project owns

### Rails app

Rails owns accounts, therapist profile data, verification, billing, free founding user status, email capture, profile contact events, referral kit data, partner source tracking, and API responses.

### Next.js app

Next.js owns public pages, parent search pages, public profile pages, empty states, public signup prompts, content pages, and server-side calls to Rails.

Rails should not send full user records or sensitive fields to Next.js.

## Working rule

Do not build the business around search rankings, AI recommendations, or Google traffic.

Build for direct visits, shared profile links, trusted referrals, parent email interest, and therapist-owned sharing.

## Phase 1: Free founding therapist profiles

### Scope

Let pediatric therapists create free founding profiles before and during launch.

The offer should be clear:

Free founding profile for pediatric therapists. No credit card. Stay free through launch. Verified profiles only.

### Rails work

- Add a clear way to mark a therapist as a free founding user.
- Keep the free founding path separate from paid checkout.
- Do not require a credit card for founding users.
- Store the join source if it is known.
- Keep verification required before a therapist is treated as trusted.
- Make the free founding status easy to remove from the public offer later.

### Next.js work

- Update public copy so it does not depend on search traffic.
- Add founding profile calls to action.
- Add "share this with a therapist" to empty search states.

### Validation

- A therapist can join as a free founding user without entering a card.
- The therapist can still be verified.
- The app can tell the difference between free founding, free unpaid, trial, and paid users.

## Phase 2: Parent demand capture

### Scope

When a parent searches an area with few or no therapists, save their interest.

### Rails work

- Add a parent interest record for ZIP code, therapy type, email, date, and source page.
- Do not collect health details in this form.
- Rate limit submissions.
- Send a confirmation email.
- Make repeat submissions from the same email and ZIP safe.
- Add a simple admin view or export later if needed.

### Next.js work

- Add "email me when therapists join near me" to empty search states.
- Add "email me therapists near this ZIP code" where useful.

### Validation

- A parent in an empty area can leave an email.
- A repeated submission does not create messy duplicate records.
- Confirmation email works.
- The saved record does not contain private medical details.

## Phase 3: Therapist referral kit

### Scope

Give therapists tools they can use to share their profile without depending on search traffic.

### Rails work

Add a referral kit to the therapist dashboard:

- Copy profile link
- Download one-page referral sheet
- Email signature snippet
- Website badge
- QR code
- "Share with a parent" button
- "Share with a pediatrician" button
- Basic profile view and contact stats

Rails should own any generated data and saved stats.

### Next.js work

- Public profiles should be readable and useful when shared by text, email, school staff, doctors, or parent groups.
- Public profile pages should make contact paths obvious.

### Validation

- A therapist can share their profile in under one minute.
- The shared profile works as a trusted referral page.
- Stats show whether the profile is getting views and contacts.

## Phase 4: No-ad therapist acquisition

### Scope

Get free users through direct outreach and trusted communities.

### Best first sources

- Ashley's pediatric therapy network
- Pediatric OT private practice groups
- Pediatric SLP private practice groups
- Pediatric PT groups
- Feeding therapy groups
- Early intervention provider groups
- Play therapy groups
- Educational therapy groups
- Neurodiversity-affirming provider groups
- State and national professional associations
- Therapists already paying for general directories
- New private practice owners

### Outreach message

```text
Hi [Name], I am Ashley, a pediatric OT building Therasaurus, a national pediatric therapy directory for families.

I am adding founding therapists before launch and offering free verified profiles right now. No credit card.

Would you want me to send you the signup link?
```

### Rails work

- Keep signup fast.
- Track source links when they are used.
- Make it easy to see how many founding therapists joined.
- Do not build a complex sales system yet.

### Next.js work

- Make the public offer page clear enough to send in outreach.
- Make social previews look trustworthy.

## Phase 5: Partner sharing

### Scope

Make Therasaurus useful to people who refer families.

### Partner groups

- Pediatricians
- Schools
- Preschools
- Parent coaches
- Early intervention programs
- Autism clinics
- Local parent group admins
- Therapist associations

### Rails work

- Track partner source links if they become useful.
- Support partner-friendly exports only if a real partner asks for them.

### Next.js work

- Create public pages or downloads partners can share.
- Keep pages focused on helping families find care.

## Phase 6: Content that earns trust

### Scope

Support a small number of useful parent pages.

Do not create bulk content just to chase search traffic.

### Useful content ideas

- Questions to ask before starting therapy
- How to know which therapy type your child may need
- What to bring to the first therapy visit
- How early intervention works by state
- How to compare two therapists
- What different credentials mean

### Rails work

No Rails work is needed unless the content saves parent interest, sends email, or reads account data.

### Next.js work

- Keep author names, credentials, dates, and sources visible.
- Link content to useful search and profile pages.

## Phase 7: Measure direct demand

### Main numbers

- Free founding therapists
- Verified public profiles
- Parent email signups
- ZIP codes with parent demand
- Profile shares
- Profile views
- Contact form starts
- Contact form submissions
- Partner source visits
- Direct visits
- Returning parents
- Paying therapists later

### Rails work

- Store account, referral kit, email interest, and profile contact events.
- Keep stats simple enough for one person to maintain.

### Next.js work

- Track public page and public profile events without collecting sensitive details.
- Report search traffic separately as extra upside.

## API boundaries

Rails should expose only the public fields the Next.js app needs.

Useful future API areas:

- Public therapist search
- Public therapist profile
- Parent email interest
- Public contact form
- Public profile view tracking
- Profile share event tracking

Rails should validate all input from Next.js.

Rails should rate limit public write endpoints.

Rails should make repeat submissions safe when a user refreshes, retries, or submits twice.

## Temporary mismatches to expect

### Rails can support a feature before Next.js shows it

Example: Rails may store parent ZIP interest before the public empty state is live.

This is fine. The unused Rails path should stay hidden until Next.js is ready.

### Next.js can link to a feature before Rails finishes it

Avoid this when possible. If it happens, the public page should use waitlist language instead of promising an active feature.

### Free founding profiles can exist before paid plans are final

This is fine. Keep the free founding status explicit so it can be handled cleanly later.

## Risks

- A national launch can look empty in many places.
- Therapists may not care about a profile unless it is easy to share.
- Parents may leave if empty search results do not offer a next step.
- Free users can create support work if the offer is unclear.
- Email capture can become risky if it asks for health details.

## Near-term priority

Start with these three things:

1. Free founding therapist profile offer.
2. Empty search state that captures parent demand.
3. Therapist referral kit.

These create value without ads and without relying on search traffic.
