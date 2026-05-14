class AddNameToPublicSearchPoints < ActiveRecord::Migration[8.1]
  def up
    add_column :public_search_points, :name, :string

    execute <<~SQL.squish
      UPDATE public_search_points
      SET name = CASE
        WHEN use_practice_name IS TRUE AND NULLIF(BTRIM(practice_name), '') IS NOT NULL
          THEN practice_name
        ELSE CONCAT_WS(
          ' ',
          NULLIF(BTRIM(first_name), ''),
          NULLIF(BTRIM(last_name), ''),
          NULLIF(BTRIM(credentials), '')
        )
      END
    SQL

    change_column_null :public_search_points, :name, false
  end

  def down
    remove_column :public_search_points, :name
  end
end
