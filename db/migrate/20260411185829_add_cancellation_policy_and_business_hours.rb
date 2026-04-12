class AddCancellationPolicyAndBusinessHours < ActiveRecord::Migration[8.1]
  def change
    add_column :therapists, :appointment_cancellation_policy, :text

    create_table :business_hours, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.integer :day_of_week, limit: 2, null: false
      # 0 = Sunday, 1 = Monday, ..., 6 = Saturday
      t.time :open_time, null: false
      t.time :close_time, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :business_hours, [:therapist_id, :day_of_week, :open_time], unique: true, name: "index_business_hours_unique_block"
    add_check_constraint :business_hours, "day_of_week BETWEEN 0 AND 6", name: "business_hours_day_range"
    add_check_constraint :business_hours, "close_time > open_time", name: "business_hours_time_order"
  end
end
