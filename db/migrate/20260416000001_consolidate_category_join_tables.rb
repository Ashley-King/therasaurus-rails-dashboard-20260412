class ConsolidateCategoryJoinTables < ActiveRecord::Migration[8.1]
  def up
    # Copy specialty data from old table (category_id) to new table (specialty_category_id)
    execute <<~SQL
      INSERT INTO specialty_to_categories (specialty_id, specialty_category_id, created_at, updated_at)
      SELECT specialty_id, category_id, created_at, updated_at
      FROM specialty_to_category
      ON CONFLICT (specialty_id, specialty_category_id) DO NOTHING
    SQL

    # Copy service data from old table (category_id) to new table (service_category_id)
    execute <<~SQL
      INSERT INTO service_to_categories (service_id, service_category_id, created_at, updated_at)
      SELECT service_id, category_id, created_at, updated_at
      FROM service_to_category
      ON CONFLICT (service_id, service_category_id) DO NOTHING
    SQL

    # Drop old tables
    drop_table :specialty_to_category
    drop_table :service_to_category
  end

  def down
    # Recreate old tables
    create_table :specialty_to_category, id: false do |t|
      t.uuid :specialty_id, null: false
      t.uuid :category_id, null: false
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.timestamptz :updated_at, null: false, default: -> { "now()" }
    end
    execute "ALTER TABLE specialty_to_category ADD PRIMARY KEY (specialty_id, category_id)"
    add_foreign_key :specialty_to_category, :specialties, name: "specialty_to_category_specialty_id_fkey"
    add_foreign_key :specialty_to_category, :specialty_categories, column: :category_id, name: "specialty_to_category_category_id_fkey"

    create_table :service_to_category, id: false do |t|
      t.uuid :service_id, null: false
      t.uuid :category_id, null: false
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.timestamptz :updated_at, null: false, default: -> { "now()" }
    end
    execute "ALTER TABLE service_to_category ADD PRIMARY KEY (service_id, category_id)"
    add_foreign_key :service_to_category, :services, name: "service_to_category_service_id_fkey"
    add_foreign_key :service_to_category, :service_categories, column: :category_id, name: "service_to_category_category_id_fkey"

    # Copy data back
    execute <<~SQL
      INSERT INTO specialty_to_category (specialty_id, category_id, created_at, updated_at)
      SELECT specialty_id, specialty_category_id, created_at, updated_at
      FROM specialty_to_categories
    SQL

    execute <<~SQL
      INSERT INTO service_to_category (service_id, category_id, created_at, updated_at)
      SELECT service_id, service_category_id, created_at, updated_at
      FROM service_to_categories
    SQL
  end
end
