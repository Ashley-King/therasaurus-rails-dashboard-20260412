class CreatePublicSearchPoints < ActiveRecord::Migration[8.1]
  def up
    create_table :public_search_points, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :therapist_id, null: false
      t.uuid :source_id, null: false
      t.string :source_type, null: false
      t.integer :source_rank, null: false
      t.string :city, null: false
      t.string :state, limit: 2, null: false
      t.string :postal_code, limit: 10, null: false
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.string :unique_id, null: false
      t.string :profile_slug, null: false
      t.string :membership_status, null: false
      t.string :profession_name, null: false
      t.string :profession_type
      t.string :location_line
      t.boolean :show_phone_number, default: false, null: false
      t.string :phone_number
      t.string :phone_ext
      t.string :practice_name
      t.boolean :use_practice_name, default: false, null: false
      t.string :practice_image_key
      t.string :practice_description
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :credentials
      t.boolean :accepting_new_clients, default: true, null: false
      t.boolean :has_waitlist, default: false, null: false
      t.boolean :accepts_insurance, default: false, null: false
      t.boolean :free_phone_call, default: true, null: false
      t.boolean :virtual, default: false, null: false
      t.boolean :in_person, default: true, null: false
      t.jsonb :specialties, default: [], null: false
      t.jsonb :services, default: [], null: false
      t.jsonb :languages, default: [], null: false
      t.boolean :credentials_verified, default: false, null: false
      t.datetime :refreshed_at, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }, null: false

      t.check_constraint "source_type IN ('primary', 'additional', 'targeted_postal_code')",
        name: "public_search_points_source_type_check"
      t.check_constraint "latitude BETWEEN -90 AND 90", name: "public_search_points_latitude_check"
      t.check_constraint "longitude BETWEEN -180 AND 180", name: "public_search_points_longitude_check"
      t.check_constraint "NOT (latitude = 0 AND longitude = 0)", name: "public_search_points_nonzero_coordinates_check"
    end

    add_foreign_key :public_search_points, :therapists, on_delete: :cascade

    add_index :public_search_points, [ :source_type, :source_id ],
      unique: true,
      name: "index_public_search_points_on_source"
    add_index :public_search_points, :therapist_id
    add_index :public_search_points, :profession_type
    add_index :public_search_points, "lower(profession_name)",
      name: "index_public_search_points_on_lower_profession_name"
    add_index :public_search_points,
      "(ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)::geography)",
      using: :gist,
      name: "index_public_search_points_on_geography"

    execute "ALTER TABLE public_search_points ENABLE ROW LEVEL SECURITY;"
  end

  def down
    drop_table :public_search_points
  end
end
