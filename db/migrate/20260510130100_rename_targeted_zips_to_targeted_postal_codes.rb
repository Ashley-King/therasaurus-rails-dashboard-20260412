class RenameTargetedZipsToTargetedPostalCodes < ActiveRecord::Migration[8.1]
  def change
    rename_table :therapist_targeted_zips, :therapist_targeted_postal_codes
    rename_column :therapist_targeted_postal_codes, :zip, :postal_code

    remove_index :therapist_targeted_postal_codes, column: :therapist_id
    remove_index :therapist_targeted_postal_codes, column: [ :therapist_id, :postal_code ]
    add_index :therapist_targeted_postal_codes,
      :therapist_id,
      name: "idx_targeted_postal_codes_therapist_id"
    add_index :therapist_targeted_postal_codes,
      [ :therapist_id, :postal_code ],
      unique: true,
      name: "idx_targeted_postal_codes_unique_postal_code"
  end
end
