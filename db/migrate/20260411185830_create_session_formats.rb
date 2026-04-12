class CreateSessionFormats < ActiveRecord::Migration[8.1]
  def change
    create_table :session_formats, id: :uuid, default: "gen_random_uuid()" do |t|
      t.text :name, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :session_formats, :name, unique: true

    create_table :practice_session_formats, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :session_format, type: :uuid, null: false, foreign_key: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :practice_session_formats, [:therapist_id, :session_format_id], unique: true, name: "idx_practice_session_formats_unique"
  end
end
