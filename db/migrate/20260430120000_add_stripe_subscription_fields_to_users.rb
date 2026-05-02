class AddStripeSubscriptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :trial_started_at, :datetime
    add_column :users, :current_period_end, :datetime
    add_column :users, :subscription_status, :string

    add_index :users, :stripe_subscription_id, unique: true
  end
end
