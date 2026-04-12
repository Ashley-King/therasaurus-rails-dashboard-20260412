class CreateJoinTables < ActiveRecord::Migration[8.1]
  def change
    create_practice_join :practice_specialties, :specialty do |t|
      t.boolean :is_focus, default: false, null: false
    end

    create_practice_join :practice_services, :service
    create_practice_join :practice_insurance_companies, :insurance_company
    create_practice_join :practice_payment_methods, :payment_method
    create_practice_join :practice_age_groups, :age_group
    create_practice_join :practice_languages, :language
    create_practice_join :practice_faiths, :faith
    create_practice_join :practice_accessibility_options, :accessibility_option
    create_practice_join :user_genders, :gender
    create_practice_join :user_race_ethnicities, :race_ethnicity
  end

  private

  def create_practice_join(table_name, ref_name, &block)
    create_table table_name, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :therapist, type: :uuid, null: false, foreign_key: true
      t.references ref_name, type: :uuid, null: false, foreign_key: true
      block&.call(t)
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index table_name, [:therapist_id, :"#{ref_name}_id"], unique: true
  end
end
