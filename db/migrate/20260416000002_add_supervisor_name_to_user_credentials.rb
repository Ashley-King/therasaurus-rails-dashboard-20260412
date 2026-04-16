class AddSupervisorNameToUserCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :user_credentials, :supervisor_name, :string
  end
end
