class EnableRlsOnTherapistMessages < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE #{quote_table_name(:therapist_messages)} ENABLE ROW LEVEL SECURITY"
  end

  def down
    execute "ALTER TABLE #{quote_table_name(:therapist_messages)} DISABLE ROW LEVEL SECURITY"
  end
end
