class CreateTherapistEducation < ActiveRecord::Migration[8.1]
  def change
    create_table :therapist_education, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: true
      t.references :college, type: :uuid, null: false, foreign_key: true
      t.references :degree_type, type: :uuid, foreign_key: true
      t.integer :graduation_year

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    create_table :therapist_continuing_education, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: true
      t.text :description, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
