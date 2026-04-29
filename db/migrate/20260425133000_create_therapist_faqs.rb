class CreateTherapistFaqs < ActiveRecord::Migration[8.1]
  def change
    create_table :therapist_faqs, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :question, null: false, limit: 200
      t.text :answer, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
