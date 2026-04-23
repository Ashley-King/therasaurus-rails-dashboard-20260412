class AddUniqueIndexOnUserCredentialsTherapistId < ActiveRecord::Migration[8.1]
  def change
    remove_index :user_credentials, :therapist_id
    add_index :user_credentials, :therapist_id, unique: true
  end
end
