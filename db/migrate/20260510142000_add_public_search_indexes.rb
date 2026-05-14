class AddPublicSearchIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_locations_on_public_search_geography
      ON locations
      USING gist (
        (ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)::geography)
      )
      WHERE geocode_status = 'ok'
        AND latitude IS NOT NULL
        AND longitude IS NOT NULL
        AND location_type IN ('primary', 'additional');
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_targeted_postal_codes_on_public_search_geography
      ON therapist_targeted_postal_codes
      USING gist (
        (ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)::geography)
      )
      WHERE geocode_status = 'ok'
        AND latitude IS NOT NULL
        AND longitude IS NOT NULL;
    SQL

    add_index :locations,
      [ :therapist_id, :location_type, :geocode_status ],
      name: "index_locations_on_public_search_eligibility",
      algorithm: :concurrently,
      if_not_exists: true

    add_index :users,
      [ :membership_status, :is_banned ],
      name: "index_users_on_public_search_visibility",
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :users,
      name: "index_users_on_public_search_visibility",
      algorithm: :concurrently,
      if_exists: true

    remove_index :locations,
      name: "index_locations_on_public_search_eligibility",
      algorithm: :concurrently,
      if_exists: true

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_targeted_postal_codes_on_public_search_geography;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_locations_on_public_search_geography;"
  end
end
