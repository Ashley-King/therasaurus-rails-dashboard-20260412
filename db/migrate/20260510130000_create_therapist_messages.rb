class CreateTherapistMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :therapist_messages, id: :uuid do |t|
      t.references :therapist, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :sender_name, null: false, limit: 120
      t.string :sender_email, null: false, limit: 254
      t.string :sender_phone, limit: 40
      t.text :body, null: false
      t.string :page_url, limit: 1000
      t.string :delivery_status, null: false, default: "pending", limit: 20
      t.integer :delivery_attempts, null: false, default: 0
      t.datetime :delivered_at
      t.datetime :failed_at
      t.text :last_delivery_error
      t.timestamps

      t.index :delivery_status
      t.index :created_at
    end
  end
end
