class CreateUserCredentials < ActiveRecord::Migration[8.1]
  def change
    create_enum :credential_status, %w[PENDING_REVIEW VERIFIED REVOKED EXPIRED]

    create_table :user_credentials, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: true
      t.string :credential_type, null: false
      t.string :credential_document
      t.string :credential_document_original_name
      t.text :credential_note

      # License fields
      t.string :license_id
      t.references :license_state, type: :uuid, foreign_key: { to_table: :states }
      t.date :license_expiration_date

      # Certificate fields
      t.string :certificate_id
      t.string :certificate_institution
      t.date :certificate_expiration_date

      # Organization credential fields
      t.string :organization_credential_id
      t.string :organization_name
      t.date :organization_expiration_date
      t.references :credential_organization, type: :uuid, foreign_key: true
      t.string :organization_credential_level

      # Status tracking
      t.enum :credential_status, enum_type: :credential_status, default: "PENDING_REVIEW", null: false
      t.datetime :verified_at
      t.datetime :pending_since, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :revoked_at
      t.text :revoked_reason
      t.datetime :first_submitted_at
      t.datetime :grace_expires_at
      t.datetime :last_reminder_sent_at
      t.string :last_reminder_type
      t.datetime :last_verified_expires_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
