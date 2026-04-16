class CreateCategoryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :specialty_categories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :specialty_categories, :name, unique: true

    create_table :service_categories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :service_categories, :name, unique: true

    create_table :specialty_to_categories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :specialty, type: :uuid, null: false, foreign_key: true
      t.references :specialty_category, type: :uuid, null: false, foreign_key: true
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :specialty_to_categories, [ :specialty_id, :specialty_category_id ], unique: true, name: "idx_specialty_to_categories_unique"

    create_table :service_to_categories, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :service, type: :uuid, null: false, foreign_key: true
      t.references :service_category, type: :uuid, null: false, foreign_key: true
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :service_to_categories, [ :service_id, :service_category_id ], unique: true, name: "idx_service_to_categories_unique"
  end
end
