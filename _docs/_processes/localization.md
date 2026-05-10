# Localization + Country Rules

The app is prepared for future localization, but English is the only
active language today.

## Locales

- `I18n.available_locales` is `[:en]`.
- `I18n.default_locale` is `:en`.
- Development and test raise on missing translations.
- Production keeps locale fallbacks enabled.
- There is no locale switcher.
- There are no translated routes.
- Future country default locales, such as `en-CA` and `es-MX`, are stored
  on `countries` rows but are not used until those locales are added to
  `I18n.available_locales`.

## Countries

Country launch rules live on normal `countries` columns:

| Code | Name | Active | Default locale | Currency | Postal label | Area label |
|---|---|---|---|---|---|---|
| `US` | United States | Yes | `en` | `USD` | `ZIP code` | `State` |
| `CA` | Canada | No | `en-CA` | `CAD` | `Postal code` | `Province` |
| `MX` | Mexico | No | `es-MX` | `MXN` | `Postal code` | `State` |

Only active countries can be selected or saved. Canada and Mexico are
backend preparation only. They must stay hidden until a separate country
launch explicitly activates them. Do not show them as "coming soon".

## Postal Codes

United States ZIP codes are the only accepted postal codes today.

- `Country#accepts_postal_code?` accepts active United States 5 digit ZIP
  codes.
- Canada and Mexico postal code formats are not accepted yet because
  those countries are inactive.
- `zip_lookups` is still a United States ZIP reference table.
- `locations.zip` is intentionally unchanged for now.
- `therapist_targeted_postal_codes.postal_code` uses country-aware
  validation but still runs through United States ZIP lookup behavior.

## Server Rules

- `CreateAccountController` loads `Country.active` only.
- `CreateAccountController` rejects inactive or fake country IDs.
- `Therapist` validates that its country is active.
- Browser country options are only display. They are not trusted for
  authorization or country access.
