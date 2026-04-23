class CreateTherapistTargetedZips < ActiveRecord::Migration[8.1]
  def change
    create_table :therapist_targeted_zips, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :therapist_id, null: false
      t.string :zip, null: false, limit: 10
      t.string :city, null: false, limit: 100
      t.string :state, null: false, limit: 2
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.boolean :city_match_successful, null: false, default: false
      t.string :geocode_status, null: false, default: "pending", limit: 20
      t.datetime :geocoded_at

      t.timestamps
    end

    add_foreign_key :therapist_targeted_zips, :therapists, on_delete: :cascade
    add_index :therapist_targeted_zips, :therapist_id
    add_index :therapist_targeted_zips, [ :therapist_id, :zip ], unique: true
  end
end
