class CreateFeatureRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :feature_requests, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.text :body, null: false
      t.string :page_url
      t.string :status, null: false, default: "open"

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :feature_requests, :kind
    add_index :feature_requests, :status
    add_index :feature_requests, :created_at
  end
end
