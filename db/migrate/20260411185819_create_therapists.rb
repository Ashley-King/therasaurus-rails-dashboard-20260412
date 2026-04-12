class CreateTherapists < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :therapists, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :unique_id
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :profile_slug
      t.references :profession, type: :uuid, null: false, foreign_key: true
      t.references :country, type: :uuid, null: false, foreign_key: true
      t.string :pronouns
      t.string :credentials
      t.integer :year_began_practice
      t.boolean :allow_messages, default: true, null: false

      # Practice details
      t.string :practice_name
      t.boolean :use_practice_name, default: false, null: false
      t.string :practice_website_url
      t.string :practice_video_url
      t.string :practice_image_url
      t.string :practice_description
      t.string :phone_number
      t.string :phone_ext
      t.boolean :show_phone_number, default: true
      t.jsonb :social_media, default: {}

      # Fees
      t.decimal :evaluation_fee
      t.decimal :therapy_fee
      t.decimal :group_therapy_fee
      t.decimal :consultation_fee
      t.decimal :late_cancellation_fee
      t.string :fee_notes

      # Availability
      t.boolean :free_phone_call, default: true, null: false
      t.boolean :accepting_new_clients, default: true, null: false
      t.boolean :has_waitlist, default: false, null: false
      t.boolean :early_morning, default: false, null: false
      t.boolean :evening, default: false, null: false
      t.boolean :weekend, default: false, null: false
      t.boolean :in_person, default: true, null: false
      t.boolean :virtual, default: false, null: false
      t.boolean :accepts_insurance, default: false, null: false
      t.string :availability_notes

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :therapists, :profile_slug, unique: true
    add_index :therapists, :unique_id, unique: true
  end
end
