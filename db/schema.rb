# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_23_222658) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.hypopg"
  enable_extension "extensions.index_advisor"
  enable_extension "extensions.moddatetime"
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pg_trgm"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.postgis"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.pg_cron"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgsodium.pgsodium"
  enable_extension "vault.supabase_vault"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "public.credential_status", ["PENDING_REVIEW", "VERIFIED", "REVOKED", "EXPIRED"]
  create_enum "public.insurance_status", ["pending", "approved", "rejected", "merged"]
  create_enum "public.location_type", ["primary", "additional"]

  create_table "public.accessibility_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false

    t.unique_constraint ["name"], name: "accessibility_options_name_key"
  end

  create_table "public.admin_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "admin_email", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false

    t.unique_constraint ["admin_email"], name: "admin_emails_email_key"
  end

  create_table "public.age_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.integer "sort_order"
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.index ["sort_order"], name: "index_age_groups_on_sort_order"

    t.unique_constraint ["name"], name: "age_groups_name_key"
  end

  create_table "public.business_hours", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.time "close_time", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "day_of_week", limit: 2, null: false
    t.time "open_time", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["therapist_id", "day_of_week", "open_time"], name: "index_business_hours_unique_block", unique: true
    t.index ["therapist_id"], name: "index_business_hours_on_therapist_id"
    t.check_constraint "close_time > open_time", name: "business_hours_time_order"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "business_hours_day_of_week_check"
  end

  create_table "public.colleges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }
    t.text "name", null: false
    t.text "status", default: "approved"
    t.uuid "submitted_by_therapist_id"
    t.timestamptz "updated_at", default: -> { "now()" }

    t.unique_constraint ["name"], name: "colleges_name_key"
  end

  create_table "public.countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "code", null: false
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["code"], name: "countries_code_key"
    t.unique_constraint ["name"], name: "countries_name_key"
  end

  create_table "public.credential_organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.boolean "requires_expiration", default: true, null: false
    t.boolean "requires_member_id", default: true, null: false
    t.text "slug", null: false
    t.text "support_notes"
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "verification_url"

    t.unique_constraint ["slug"], name: "credential_organizations_slug_key"
  end

  create_table "public.degree_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "abbreviation", null: false
    t.text "category"
    t.timestamptz "created_at", default: -> { "now()" }
    t.text "name", null: false
    t.text "status", default: "approved"
    t.uuid "submitted_by_therapist_id"
    t.timestamptz "updated_at", default: -> { "now()" }

    t.unique_constraint ["abbreviation"], name: "degree_types_abbreviation_key"
  end

  create_table "public.faiths", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "faiths_name_key"
  end

  create_table "public.genders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "genders_name_key"
  end

  create_table "public.insurance_companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }
    t.text "name", null: false
    t.enum "status", default: "pending", null: false, enum_type: "insurance_status"
    t.uuid "submitted_by_therapist_id"
    t.timestamptz "updated_at", default: -> { "now()" }
    t.index ["status"], name: "idx_insurance_companies_status"
    t.index ["submitted_by_therapist_id"], name: "idx_insurance_companies_submitted_by"
    t.unique_constraint ["name"], name: "insurance_companies_name_key"
  end

  create_table "public.languages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", null: false
    t.text "name", null: false
    t.timestamptz "updated_at", null: false

    t.unique_constraint ["name"], name: "languages_name_key"
  end

  create_table "public.locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "canonical_city"
    t.string "canonical_state"
    t.string "city", null: false
    t.boolean "city_match_successful", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "geocode_last_enqueued_at"
    t.string "geocode_status", default: "pending", null: false
    t.datetime "geocoded_at"
    t.decimal "latitude"
    t.enum "location_type", enum_type: "location_type"
    t.decimal "longitude"
    t.boolean "show_street_address", default: true
    t.string "state", null: false
    t.string "street_address", null: false
    t.string "street_address2"
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "zip", null: false
    t.index ["therapist_id"], name: "index_locations_on_therapist_id"
  end

  create_table "public.payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", null: false
    t.text "name", null: false
    t.timestamptz "updated_at", null: false

    t.unique_constraint ["name"], name: "payment_methods_name_key"
  end

  create_table "public.practice_accessibility_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "accessibility_option_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["accessibility_option_id"], name: "idx_on_accessibility_option_id_f84abd0c14"
    t.index ["therapist_id", "accessibility_option_id"], name: "idx_on_therapist_id_accessibility_option_id_1dd845fe1d", unique: true
    t.index ["therapist_id"], name: "index_practice_accessibility_options_on_therapist_id"
  end

  create_table "public.practice_age_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "age_group_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["age_group_id"], name: "index_practice_age_groups_on_age_group_id"
    t.index ["therapist_id", "age_group_id"], name: "index_practice_age_groups_on_therapist_id_and_age_group_id", unique: true
    t.index ["therapist_id"], name: "index_practice_age_groups_on_therapist_id"
  end

  create_table "public.practice_faiths", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "faith_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["faith_id"], name: "index_practice_faiths_on_faith_id"
    t.index ["therapist_id", "faith_id"], name: "index_practice_faiths_on_therapist_id_and_faith_id", unique: true
    t.index ["therapist_id"], name: "index_practice_faiths_on_therapist_id"
  end

  create_table "public.practice_insurance_companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "insurance_company_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["insurance_company_id"], name: "index_practice_insurance_companies_on_insurance_company_id"
    t.index ["therapist_id", "insurance_company_id"], name: "idx_on_therapist_id_insurance_company_id_e3867d6f24", unique: true
    t.index ["therapist_id"], name: "index_practice_insurance_companies_on_therapist_id"
  end

  create_table "public.practice_languages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "language_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["language_id"], name: "index_practice_languages_on_language_id"
    t.index ["therapist_id", "language_id"], name: "index_practice_languages_on_therapist_id_and_language_id", unique: true
    t.index ["therapist_id"], name: "index_practice_languages_on_therapist_id"
  end

  create_table "public.practice_payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "payment_method_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["payment_method_id"], name: "index_practice_payment_methods_on_payment_method_id"
    t.index ["therapist_id", "payment_method_id"], name: "idx_on_therapist_id_payment_method_id_c4a96d4c1a", unique: true
    t.index ["therapist_id"], name: "index_practice_payment_methods_on_therapist_id"
  end

  create_table "public.practice_services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "service_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["service_id"], name: "index_practice_services_on_service_id"
    t.index ["therapist_id", "service_id"], name: "index_practice_services_on_therapist_id_and_service_id", unique: true
    t.index ["therapist_id"], name: "index_practice_services_on_therapist_id"
  end

  create_table "public.practice_session_formats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "session_format_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["therapist_id", "session_format_id"], name: "idx_practice_session_formats_unique", unique: true
  end

  create_table "public.practice_telehealth_platforms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "telehealth_platform_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["telehealth_platform_id"], name: "index_practice_telehealth_platforms_on_telehealth_platform_id"
    t.index ["therapist_id", "telehealth_platform_id"], name: "idx_practice_telehealth_platforms_unique", unique: true
    t.index ["therapist_id"], name: "index_practice_telehealth_platforms_on_therapist_id"
  end

  create_table "public.practice_specialties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_focus", default: false, null: false
    t.uuid "specialty_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["specialty_id"], name: "index_practice_specialties_on_specialty_id"
    t.index ["therapist_id", "specialty_id"], name: "index_practice_specialties_on_therapist_id_and_specialty_id", unique: true
    t.index ["therapist_id"], name: "index_practice_specialties_on_therapist_id"
  end

  create_table "public.profession_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "profession_types_name_key"
  end

  create_table "public.professions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "can_be_supervisor", default: false, null: false
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.uuid "profession_type_id", null: false
    t.text "slug", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "professions_name_key"
    t.unique_constraint ["slug"], name: "professions_slug_unique"
  end

  create_table "public.race_ethnicities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "race_ethnicities_name_key"
  end

  create_table "public.service_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.string "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.index ["name"], name: "index_service_categories_on_name", unique: true
    t.unique_constraint ["name"], name: "service_categories_name_key"
  end

  create_table "public.service_to_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "service_category_id", null: false
    t.uuid "service_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["service_category_id"], name: "index_service_to_categories_on_service_category_id"
    t.index ["service_id", "service_category_id"], name: "idx_service_to_categories_unique", unique: true
    t.index ["service_id"], name: "index_service_to_categories_on_service_id"
  end

  create_table "public.services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.string "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "services_name_key"
  end

  create_table "public.session_formats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "session_formats_name_key"
  end

  create_table "public.telehealth_platforms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false

    t.index ["name"], name: "index_telehealth_platforms_on_name", unique: true
  end

  create_table "public.specialties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.string "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["name"], name: "specialties_name_key"
  end

  create_table "public.specialty_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.string "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.index ["name"], name: "index_specialty_categories_on_name", unique: true
    t.unique_constraint ["name"], name: "specialty_categories_name_key"
  end

  create_table "public.specialty_to_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "specialty_category_id", null: false
    t.uuid "specialty_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["specialty_category_id"], name: "index_specialty_to_categories_on_specialty_category_id"
    t.index ["specialty_id", "specialty_category_id"], name: "idx_specialty_to_categories_unique", unique: true
    t.index ["specialty_id"], name: "index_specialty_to_categories_on_specialty_id"
  end

  create_table "public.states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "code", null: false
    t.timestamptz "created_at", default: -> { "timezone('utc'::text, now())" }, null: false
    t.text "name", null: false
    t.timestamptz "updated_at", default: -> { "timezone('utc'::text, now())" }, null: false

    t.unique_constraint ["code"], name: "states_code_key"
    t.unique_constraint ["name"], name: "states_name_key"
  end

  create_table "public.therapist_continuing_education", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "year"
    t.index ["therapist_id"], name: "index_therapist_continuing_education_on_therapist_id"
  end

  create_table "public.therapist_education", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "college_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "degree_type_id"
    t.integer "graduation_year"
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["college_id"], name: "index_therapist_education_on_college_id"
    t.index ["degree_type_id"], name: "index_therapist_education_on_degree_type_id"
    t.index ["therapist_id"], name: "index_therapist_education_on_therapist_id"
  end

  create_table "public.therapist_targeted_zips", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "city", limit: 100, null: false
    t.boolean "city_match_successful", default: false, null: false
    t.datetime "created_at", null: false
    t.string "geocode_status", limit: 20, default: "pending", null: false
    t.datetime "geocoded_at"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "state", limit: 2, null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", null: false
    t.string "zip", limit: 10, null: false
    t.index ["therapist_id", "zip"], name: "index_therapist_targeted_zips_on_therapist_id_and_zip", unique: true
    t.index ["therapist_id"], name: "index_therapist_targeted_zips_on_therapist_id"
  end

  create_table "public.therapists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "accepting_new_clients", default: true, null: false
    t.boolean "accepts_insurance", default: false, null: false
    t.boolean "allow_messages", default: true, null: false
    t.text "appointment_cancellation_policy"
    t.string "availability_notes"
    t.decimal "consultation_fee"
    t.uuid "country_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "credentials"
    t.boolean "early_morning", default: false, null: false
    t.decimal "evaluation_fee"
    t.boolean "evening", default: false, null: false
    t.string "fee_notes"
    t.string "first_name", null: false
    t.boolean "free_phone_call", default: true, null: false
    t.decimal "group_therapy_fee"
    t.boolean "has_waitlist", default: false, null: false
    t.boolean "in_person", default: true, null: false
    t.string "last_name", null: false
    t.decimal "late_cancellation_fee"
    t.text "parking_transit_notes"
    t.text "personal_statement"
    t.string "phone_ext"
    t.string "phone_number"
    t.string "practice_description"
    t.string "practice_image_key"
    t.string "practice_name"
    t.string "practice_video_url"
    t.string "practice_website_url"
    t.uuid "profession_id", null: false
    t.string "profile_slug"
    t.string "pronouns"
    t.boolean "show_phone_number", default: true
    t.jsonb "social_media", default: {}
    t.string "telehealth_platform_other"
    t.decimal "therapy_fee"
    t.string "unique_id"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "use_practice_name", default: false, null: false
    t.uuid "user_id", null: false
    t.boolean "virtual", default: false, null: false
    t.boolean "weekend", default: false, null: false
    t.integer "year_began_practice"
    t.index ["country_id"], name: "index_therapists_on_country_id"
    t.index ["profession_id"], name: "index_therapists_on_profession_id"
    t.index ["profile_slug"], name: "index_therapists_on_profile_slug", unique: true
    t.index ["unique_id"], name: "index_therapists_on_unique_id", unique: true
    t.index ["user_id"], name: "index_therapists_on_user_id", unique: true
  end

  create_table "public.user_credentials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "certificate_expiration_date"
    t.string "certificate_id"
    t.string "certificate_institution"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "credential_document"
    t.string "credential_document_original_name"
    t.text "credential_note"
    t.uuid "credential_organization_id"
    t.enum "credential_status", default: "PENDING_REVIEW", null: false, enum_type: "credential_status"
    t.string "credential_type", null: false
    t.datetime "first_submitted_at"
    t.datetime "grace_expires_at"
    t.datetime "last_reminder_sent_at"
    t.string "last_reminder_type"
    t.date "license_expiration_date"
    t.string "license_id"
    t.uuid "license_state_id"
    t.string "organization_credential_id"
    t.string "organization_credential_level"
    t.date "organization_expiration_date"
    t.string "organization_name"
    t.datetime "pending_since", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "revoked_at"
    t.text "revoked_reason"
    t.string "supervisor_name"
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "verified_at"
    t.index ["credential_organization_id"], name: "index_user_credentials_on_credential_organization_id"
    t.index ["license_state_id"], name: "index_user_credentials_on_license_state_id"
    t.index ["therapist_id"], name: "index_user_credentials_on_therapist_id", unique: true
  end

  create_table "public.user_genders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "gender_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["gender_id"], name: "index_user_genders_on_gender_id"
    t.index ["therapist_id", "gender_id"], name: "index_user_genders_on_therapist_id_and_gender_id", unique: true
    t.index ["therapist_id"], name: "index_user_genders_on_therapist_id"
  end

  create_table "public.user_race_ethnicities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "race_ethnicity_id", null: false
    t.uuid "therapist_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["race_ethnicity_id"], name: "index_user_race_ethnicities_on_race_ethnicity_id"
    t.index ["therapist_id", "race_ethnicity_id"], name: "idx_on_therapist_id_race_ethnicity_id_923a381d7c", unique: true
    t.index ["therapist_id"], name: "index_user_race_ethnicities_on_therapist_id"
  end

  create_table "public.users", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "email", null: false
    t.boolean "is_admin", default: false, null: false
    t.boolean "is_banned", default: false, null: false
    t.string "membership_status", default: "member", null: false
    t.string "stripe_customer_id"
    t.datetime "trial_ends_at", precision: nil
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "public.zip_lookups", id: :serial, force: :cascade do |t|
    t.text "city", null: false
    t.text "city_alt"
    t.decimal "city_lat", precision: 10, scale: 7, null: false
    t.decimal "city_lng", precision: 10, scale: 7, null: false
    t.text "county_name"
    t.text "state_id", null: false
    t.text "state_name", null: false
    t.text "timezone"
    t.text "zip", null: false
    t.decimal "zip_lat", precision: 10, scale: 7
    t.decimal "zip_lng", precision: 10, scale: 7
    t.index ["city"], name: "idx_zip_lookups_city_trgm", using: :gin
    t.index ["zip", "state_id"], name: "idx_zip_lookups_zip_state"
    t.index ["zip"], name: "idx_zip_lookups_zip"
  end

  add_foreign_key "public.business_hours", "public.therapists", name: "business_hours_therapist_id_fkey", on_delete: :cascade
  add_foreign_key "public.locations", "public.therapists"
  add_foreign_key "public.practice_accessibility_options", "public.accessibility_options"
  add_foreign_key "public.practice_accessibility_options", "public.therapists"
  add_foreign_key "public.practice_age_groups", "public.age_groups"
  add_foreign_key "public.practice_age_groups", "public.therapists"
  add_foreign_key "public.practice_faiths", "public.faiths"
  add_foreign_key "public.practice_faiths", "public.therapists"
  add_foreign_key "public.practice_insurance_companies", "public.insurance_companies"
  add_foreign_key "public.practice_insurance_companies", "public.therapists"
  add_foreign_key "public.practice_languages", "public.languages"
  add_foreign_key "public.practice_languages", "public.therapists"
  add_foreign_key "public.practice_payment_methods", "public.payment_methods"
  add_foreign_key "public.practice_payment_methods", "public.therapists"
  add_foreign_key "public.practice_services", "public.services"
  add_foreign_key "public.practice_services", "public.therapists"
  add_foreign_key "public.practice_session_formats", "public.session_formats", name: "practice_session_formats_session_format_id_fkey"
  add_foreign_key "public.practice_session_formats", "public.therapists", name: "practice_session_formats_therapist_id_fkey", on_delete: :cascade
  add_foreign_key "public.practice_specialties", "public.specialties"
  add_foreign_key "public.practice_specialties", "public.therapists"
  add_foreign_key "public.practice_telehealth_platforms", "public.telehealth_platforms"
  add_foreign_key "public.practice_telehealth_platforms", "public.therapists", on_delete: :cascade
  add_foreign_key "public.professions", "public.profession_types", name: "professions_profession_type_id_fkey"
  add_foreign_key "public.service_to_categories", "public.service_categories"
  add_foreign_key "public.service_to_categories", "public.services"
  add_foreign_key "public.specialty_to_categories", "public.specialties"
  add_foreign_key "public.specialty_to_categories", "public.specialty_categories"
  add_foreign_key "public.therapist_continuing_education", "public.therapists"
  add_foreign_key "public.therapist_education", "public.colleges"
  add_foreign_key "public.therapist_education", "public.degree_types"
  add_foreign_key "public.therapist_education", "public.therapists"
  add_foreign_key "public.therapist_targeted_zips", "public.therapists", on_delete: :cascade
  add_foreign_key "public.therapists", "public.countries"
  add_foreign_key "public.therapists", "public.professions"
  add_foreign_key "public.therapists", "public.users", name: "therapists_user_id_fkey", on_delete: :cascade
  add_foreign_key "public.user_credentials", "public.credential_organizations"
  add_foreign_key "public.user_credentials", "public.states", column: "license_state_id"
  add_foreign_key "public.user_credentials", "public.therapists"
  add_foreign_key "public.user_genders", "public.genders"
  add_foreign_key "public.user_genders", "public.therapists"
  add_foreign_key "public.user_race_ethnicities", "public.race_ethnicities"
  add_foreign_key "public.user_race_ethnicities", "public.therapists"
  add_foreign_key "public.users", "auth.users", column: "id", name: "users_id_fkey", on_delete: :cascade

  create_table "extensions.spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "proj4text", limit: 2048
    t.string "srtext", limit: 2048
    t.check_constraint "srid > 0 AND srid <= 998999", name: "spatial_ref_sys_srid_check"
  end
end
