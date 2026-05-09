# Therapist Profile Page - Designer Field Inventory

Last verified against the app: 2026-05-09.

The public profile page is not built yet. The dashboard fields are built. This document tells the designer what data can appear on a public therapist profile and what is optional.

This is not a layout spec. The sections below are only grouped so the inventory is easy to scan. They are not a suggested page order.

For repeatable items, the designer only needs to see the shape of one item. The max count is included so the design can handle repetition.

## Final design deliverables

When the designs are finalized, include these responsive views:

| View | Screen width |
|---|---:|
| Tablet | 768 px |
| Phone | 375 px |

## Status labels used in this document

| Status | Meaning |
|---|---|
| Always shown | Every public profile should have this. |
| Optional | The therapist may leave this blank. Hide it or use a graceful empty state. |
| Conditional | Show this only when the related field or privacy toggle allows it. |
| Never public | This exists in the app, but it must not appear on the public profile. |

## Public profile rules

| Rule | What the designer needs to know |
|---|---|
| Email address | Never show the therapist's email address. The public action is an "Email me" button. |
| Phone number | If the therapist turns off "Show my phone number on my public profile," do not show the phone number and do not show any button that links to a phone call. |
| Free intro phone call | This can be shown as an offer when enabled. A phone-call button still requires a visible phone number. |
| Street address | Every profile shows at least city, state, and ZIP for each public location. Street address is shown only when that location's toggle is on. |
| Map links | Do not show a map. If a location shows its street address, it can have a "View on map" link to Google Maps for that street address. |
| Hidden street address | If the therapist hides the street address, show city, state, and ZIP only. Do not show a map link for that location. |
| Specialties | The therapist's top five. These are chosen from their Areas of Expertise. Use this exact label. |
| Areas of Expertise | The full list of topics the therapist works with. A therapist can choose up to 20. Use this exact label. |
| Services | A therapist can choose up to 20 services. |
| Empty sections | Most profile sections are optional. The design should handle missing sections cleanly. |

## Always shown or always available

| Item | Status | Notes |
|---|---|---|
| Display name | Always shown | Either the therapist's personal name or practice name. The therapist chooses. |
| Profession | Always shown | One profession from the app list. |
| Primary location city, state, ZIP | Always shown | Street address is conditional. City, state, and ZIP always show. |
| New client status | Always shown | Derived from "Accepting new clients" and "Maintain a waitlist." |
| "Email me" action | Always shown | The email address itself is never exposed. |

## Identity and profile media

| Item | Status | Notes |
|---|---|---|
| First name | Always stored | Used for personal name mode. |
| Last name | Always stored | Used for personal name mode. |
| Practice name | Optional | Can replace the personal name when the therapist chooses practice name mode. |
| Credentials text | Optional | Free text, such as "LCSW, RPT-S." |
| Pronouns | Conditional | Shown only when the therapist turns on the pronouns visibility toggle. Default is off. |
| Profile or practice image | Optional | One image. Current dashboard crop is designed for a circular image. |
| Practice video URL | Optional | URL field. |
| Practice website | Optional | URL field. |
| Social media links | Optional | Supported platforms are Facebook, Instagram, LinkedIn, Pinterest, Substack, Threads, TikTok, YouTube, and X. |
| Year began practice | Optional | Can be used to show years in practice. |
| Practice description | Optional | Rich text. Maximum 1,500 visible characters. Supports bold, italic, bullets, and numbered lists. |
| Personal statement | Optional | Separate long text field. |

## Contact actions

| Item | Status | Notes |
|---|---|---|
| Email me button | Always shown | This must not expose the email address. |
| Phone number | Conditional | Shown only when a phone number exists and the phone visibility toggle is on. |
| Phone extension | Conditional | Shown with the phone number when present. |
| Phone-call button | Conditional | Only show when the phone number is visible. |
| Free intro phone call | Conditional | Default is on. Do not make it a call link unless the phone number is visible. |
| Website link | Optional | Show only when a website URL exists. |
| Social links | Optional | Show only links that the therapist entered. |
| Repeated low-profile CTAs | Optional design pattern | I like the quiet repeated CTAs that appear throughout Psychology Today profiles. They should feel helpful and low-pressure. |

## Locations

| Item | Status | Notes |
|---|---|---|
| Primary location | Always shown | Exactly one primary location exists. |
| Additional location | Optional | At most one additional location. |
| Street address line 1 | Conditional | Show only when that location's street address toggle is on. |
| Street address line 2 | Conditional | Show only when present and street address is visible. |
| City | Always shown for each public location | Always show even when street address is hidden. |
| State | Always shown for each public location | Always show even when street address is hidden. |
| ZIP | Always shown for each public location | Always show even when street address is hidden. |
| View on map link | Conditional | Only when street address is visible. Link to Google Maps. Do not embed a map. |
| Parking and transit notes | Optional | Long text. |

## Availability and session details

| Item | Status | Notes |
|---|---|---|
| New client status | Always shown | Use these states: Accepting new clients, Waitlist, Not accepting. |
| Accepting new clients | Always stored | Default is on. Mutually exclusive with waitlist. |
| Waitlist | Conditional | Default is off. |
| In-person sessions | Conditional | Default is on. |
| Virtual or telehealth sessions | Conditional | Default is off. |
| Telehealth platforms | Optional | Show only when virtual sessions are offered and platforms are selected. |
| Other telehealth platforms | Optional | Free text. |
| Session formats | Optional | Up to 4. Individual, Family, Group, Parent-child. |
| Early morning appointments | Optional | Flag for appointments before 8 A.M. |
| Evening appointments | Optional | Flag for appointments at 6 P.M. or later. |
| Weekend appointments | Optional | Flag. |
| Business hours | Optional | Up to 7 rows. Each day is closed or has one open and close time. |
| Time zone label | Conditional | Show with business hours when hours are shown. Use a human label, such as "Eastern Time." |
| Availability notes | Optional | Short free-form text. |
| Cancellation policy | Optional | Long text. |

## Areas of Expertise, Specialties, and Services

| Item | Status | Notes |
|---|---|---|
| Specialties | Optional | The therapist's top five. These are chosen from their Areas of Expertise. Use this exact label. |
| Areas of Expertise | Optional | Up to 20. Chosen from 237 options. Use this exact label. |
| Services | Optional | Up to 20. Chosen from 145 options. |

## Who they work with

| Item | Status | Notes |
|---|---|---|
| Age groups | Optional | Up to 7. Newborns through young adults. |
| Languages | Optional | 33 options. English is assumed and is not in the stored list. |
| Faiths and belief systems | Optional | 22 options. |
| Gender identity | Conditional | 5 options. Shown only when the therapist turns on the gender visibility toggle. Default is off. |
| Race and ethnicity | Conditional | 11 options. Shown only when the therapist turns on the race and ethnicity visibility toggle. Default is off. |
| Accessibility options | Optional | 55 options. |

## Fees, payment, and insurance

| Item | Status | Notes |
|---|---|---|
| Fees section | Optional | The therapist can leave every fee blank. |
| Assessment or evaluation fee | Optional | Dollar amount. |
| Individual therapy fee | Optional | Dollar amount. |
| Group therapy fee | Optional | Dollar amount. |
| Consultation fee | Optional | Dollar amount. |
| No-show or late cancellation fee | Optional | Dollar amount. |
| Fee notes | Optional | Short text, such as sliding scale or package pricing. |
| Payment methods | Optional | 11 options. |
| Accepted insurance companies | Optional | 1,672 current options and growing. Design for a long list. |

## Credentials and education

| Item | Status | Notes |
|---|---|---|
| Credential status | Conditional | Show when a credential exists. Possible statuses are Verified, Pending, and Expired. |
| Credential type | Optional | State license, organization credential, or supervised practice. |
| State license details | Optional | State, license number, and expiration date can exist. |
| Organization credential details | Optional | Organization name, member or certificate ID, expiration date, and credential level can exist. |
| Supervised practice details | Optional | Supervisor name, state, license number, and expiration date can exist. |
| Education entry | Optional | One entry can include college, degree type, and graduation year. This can repeat up to 2 times. |
| Continuing education entry | Optional | One entry can include description and year. This can repeat up to 3 times. |

Do not show credential document uploads or credential notes.

## FAQs

| Item | Status | Notes |
|---|---|---|
| FAQ item | Optional | One FAQ has one question and one answer. This can repeat up to 5 times. |
| Question | Optional within each FAQ | Maximum 200 characters. |
| Answer | Optional within each FAQ | Maximum 1,000 characters. |

## Reference counts

These counts were verified against the local app database on 2026-05-09.

| Data type | Count | Public profile note |
|---|---:|---|
| Areas of Expertise | 237 | A therapist can show up to 20. |
| Services | 145 | A therapist can show up to 20. |
| Age groups | 7 | Optional. |
| Session formats | 4 | Optional. |
| Languages | 33 | Optional. |
| Faiths and belief systems | 22 | Optional. |
| Genders | 5 | Conditional by toggle. |
| Race and ethnicities | 11 | Conditional by toggle. |
| Payment methods | 11 | Optional. |
| Telehealth platforms | 8 | Optional. |
| Accessibility options | 55 | Optional. |
| Professions | 30 | One required. |
| Insurance companies | 1,672 | Optional and growing. |
| Colleges | 5,192 | Used for education entries. |
| Degree types | 34 | Used for education entries. |
| US states and territories | 56 | Used for locations and credentials. |

## Fixed option lists

### Age groups

Newborns (0 to 1 Month), Infants (2 Months to 1 Year), Toddlers (1 to 3 Years), Preschoolers (4 to 5 Years), School-Aged Children (6 to 11 Years), Adolescents (12 to 18 Years), Young Adults (18 to 24 Years)

### Session formats

Individual, Family, Group, Parent-child

### Payment methods

ACH Bank Transfer, Cash, Check, Credit Card, Flexible Spending Account, Health Savings Account, PayPal, Self Pay, Sliding Scale, Venmo, Zelle

### Telehealth platforms

Doxy.me, Google Meet, Jane App, Microsoft Teams, Presence, SimplePractice, TheraPlatform, Zoom for Healthcare

### Social media platforms

Facebook, Instagram, LinkedIn, Pinterest, Substack, Threads, TikTok, YouTube, X

### Genders

Intersex, Man, Non-Binary/Non-Conforming, Transgender, Woman

### Race and ethnicities

American Indian or Alaska Native, Asian, Biracial, Black or African American, Hispanic or Latino, Middle Eastern, Multiethnic, Multiracial, Native Hawaiian or Pacific Islander, South Asian, White

### Languages

American Sign Language, Arabic, Armenian, Bengali, Chinese, French, German, Greek, Gujarati, Haitian Creole, Hebrew, Hindi, Hmong, Italian, Japanese, Khmer, Korean, Navajo, Persian, Polish, Portuguese, Punjabi, Russian, Serbo-Croatian, Spanish, Tagalog, Tai-Kadai, Tamil, Telugu, Ukrainian, Urdu, Vietnamese, Yiddish

### Faiths and belief systems

Agnosticism, Atheism, Baha'i, Buddhism, Christianity, Church of Jesus Christ of Latter-Day Saints, Hinduism, Humanism, Interfaith Families, Islam, Jainism, Jehovah's Witness, Judaism, Multifaith Families, Native American Spirituality, New Thought, Secular/Non-Religious, Sikhism, Spirituality, Taoism, Unitarian Universalism, Wicca/Paganism

### Professions

Addictions Counselor, Art Therapist, Associate Clinical Social Worker, Board Certified Assistant Behavior Analyst, Board Certified Behavior Analyst, Clinical Social Worker, Counselor, Drug and Alcohol Counselor, Educational Psychologist, Educational Therapist, Licensed Professional Counselor, Licensed Psychoanalyst, Limited Licensed Psychologist, LPC Intern, Marriage and Family Therapist, Marriage and Family Therapist Associate, Marriage and Family Therapist Intern, Music Therapist, Occupational Therapist, Pastoral Counselor, Physical Therapist, Professional Clinical Counselor, Psychological Associate, Psychologist, Psychotherapist, Registered Psychotherapist, School Psychologist, Social Worker, Speech Language Pathologist, Therapist

## Empty states the design must handle

- No profile image.
- No practice description.
- No personal statement.
- No Areas of Expertise.
- No Specialties.
- No Services.
- No fees listed.
- No payment methods.
- No insurance listed.
- No business hours.
- No website.
- No social links.
- No FAQs.
- Phone number hidden.
- Street address hidden.
- All identity visibility toggles off.
- One location or two locations.
- Long practice name or short personal name.
- Long insurance list.
- Long Areas of Expertise list.
- Long Services list.
- In-person only, virtual only, or both.
- Accepting new clients, waitlist, or not accepting.
