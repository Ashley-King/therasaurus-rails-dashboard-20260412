class CreateStripeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_events, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, null: false
      t.datetime :processed_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :stripe_events, :stripe_event_id, unique: true
    add_index :stripe_events, [ :processed_at, :event_type ]
  end
end
