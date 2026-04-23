class AddSortOrderToAgeGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :age_groups, :sort_order, :integer
    add_index :age_groups, :sort_order
  end
end
