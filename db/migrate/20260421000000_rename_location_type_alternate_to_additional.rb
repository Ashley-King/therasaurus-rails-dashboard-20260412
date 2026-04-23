class RenameLocationTypeAlternateToAdditional < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TYPE location_type RENAME VALUE 'alternate' TO 'additional'"
  end

  def down
    execute "ALTER TYPE location_type RENAME VALUE 'additional' TO 'alternate'"
  end
end
