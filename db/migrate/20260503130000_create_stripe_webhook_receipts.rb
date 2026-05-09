class CreateStripeWebhookReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_webhook_receipts, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "processing"
      t.datetime :processed_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :stripe_webhook_receipts,
      [ :stripe_event_id, :event_type ],
      unique: true,
      name: "index_stripe_webhook_receipts_on_event"
    add_index :stripe_webhook_receipts, [ :status, :event_type ]
  end
end
