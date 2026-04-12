class CreateUsersAndAddUserIdToTherapists < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :email, null: false
      t.string :membership_status, null: false, default: "member"
      t.boolean :is_admin, null: false, default: false
      t.boolean :is_banned, null: false, default: false
      t.string :stripe_customer_id
      t.timestamp :trial_ends_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_reference :therapists, :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
  end
end
