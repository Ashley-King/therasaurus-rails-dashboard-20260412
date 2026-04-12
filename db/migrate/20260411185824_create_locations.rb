class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_enum :location_type, %w[primary alternate]

    create_table :locations, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: true
      t.enum :location_type, enum_type: :location_type
      t.string :street_address, null: false
      t.string :street_address2
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.boolean :show_street_address, default: true
      t.decimal :latitude
      t.decimal :longitude
      t.string :canonical_city
      t.string :canonical_state
      t.boolean :city_match_successful, default: false, null: false
      t.string :geocode_status, default: "pending", null: false
      t.datetime :geocoded_at
      t.datetime :geocode_last_enqueued_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
