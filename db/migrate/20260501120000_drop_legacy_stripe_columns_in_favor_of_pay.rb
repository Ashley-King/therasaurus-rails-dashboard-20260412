class DropLegacyStripeColumnsInFavorOfPay < ActiveRecord::Migration[8.1]
  def change
    drop_table :stripe_events, if_exists: true do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false
      t.datetime :processed_at
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    remove_index :users, :stripe_subscription_id, if_exists: true
    remove_column :users, :stripe_customer_id, :string
    remove_column :users, :stripe_subscription_id, :string
    remove_column :users, :trial_started_at, :datetime
    remove_column :users, :trial_ends_at, :datetime, precision: nil
    remove_column :users, :current_period_end, :datetime
    remove_column :users, :subscription_status, :string
  end
end
