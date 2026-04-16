# Admin Panel

## Overview

The admin panel uses [Avo](https://avohq.io) (free/community edition) mounted at `/avo`.

## Access

- Requires signed-in user with `is_admin: true`.
- Authentication reuses the existing Supabase JWT session from the `Authentication` concern.
- Non-admin users are redirected to `/dashboard`.
- Unauthenticated users are redirected to `/signin`.

## Configuration

- Initializer: `config/initializers/avo.rb`
- Resources: `app/avo/resources/`
- Route: `mount Avo::Engine` in `config/routes.rb`

## Resources

### Core models
User, Therapist, Location, UserCredential, TherapistEducation, TherapistContinuingEducation, BusinessHour, ZipLookup

### Reference tables
Specialty, Service, Language, AgeGroup, Gender, RaceEthnicity, Faith, AccessibilityOption, PaymentMethod, InsuranceCompany, SessionFormat, Country, State, Profession, ProfessionType, College, DegreeType, CredentialOrganization, AdminEmail, SpecialtyCategory, ServiceCategory

### Join tables
Not surfaced as standalone resources. Managed through parent associations (e.g. therapist -> specialties, specialty -> specialty_categories).

## Adding a new resource

1. Create `app/avo/resources/<model_name>.rb`
2. Define fields matching the model's columns
3. Avo auto-discovers the resource — no route changes needed
