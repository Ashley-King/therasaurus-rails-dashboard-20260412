# Admin Panel

## Overview

The admin panel uses [Avo](https://avohq.io) (free/community edition) mounted at `/avo`.

## Access

- Requires signed-in user with `is_admin: true`.
- Authentication reuses the existing Supabase JWT session from the `Authentication` concern.
- Non-admin users are redirected to `/account-settings` with an "Admin access required." alert.
- Unauthenticated users are redirected to `/signin`.

## Configuration

- Initializer: `config/initializers/avo.rb`
- Resources: `app/avo/resources/`
- Route: `mount Avo::Engine` in `config/routes.rb`

## Resources

### Core models
User, Therapist, Location, UserCredential, TherapistEducation, TherapistContinuingEducation, BusinessHour, ZipLookup, FeatureRequest

### Reference tables
Specialty, SpecialtyCategory, Service, ServiceCategory, Language, AgeGroup, Gender, RaceEthnicity, Faith, AccessibilityOption, PaymentMethod, InsuranceCompany, SessionFormat, TelehealthPlatform, Country, State, Profession, ProfessionType, College, DegreeType, CredentialOrganization, AdminEmail

### Join tables
Most join tables are managed through parent associations (e.g. therapist → specialties). Two are surfaced directly so categories can be edited without bouncing through the parent: `ServiceToCategory` and `SpecialtyToCategory`.

## Admin tools (outside Avo)

A small set of admin-only endpoints lives at `/admin-tools/*` (not under
the Avo engine, to avoid routing collisions). Access is gated by
`current_user.is_admin?` in the controller, not by Avo.

- `GET /admin-tools/credentials/:id/document` — mints a 5-minute
  presigned R2 URL for a credential document and redirects. Used by
  Avo's `UserCredential` resource via a "Download" link.

## Adding a new resource

1. Create `app/avo/resources/<model_name>.rb`
2. Define fields matching the model's columns
3. Avo auto-discovers the resource — no route changes needed
