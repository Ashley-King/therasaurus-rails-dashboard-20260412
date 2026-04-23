class CreateTelehealthPlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :telehealth_platforms, id: :uuid, default: "gen_random_uuid()" do |t|
      t.text :name, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :telehealth_platforms, :name, unique: true

    create_table :practice_telehealth_platforms, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :telehealth_platform, type: :uuid, null: false, foreign_key: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :practice_telehealth_platforms, [ :therapist_id, :telehealth_platform_id ],
              unique: true, name: "idx_practice_telehealth_platforms_unique"

    remove_column :therapists, :telehealth_platform, :string
    add_column :therapists, :telehealth_platform_other, :string
  end
end
