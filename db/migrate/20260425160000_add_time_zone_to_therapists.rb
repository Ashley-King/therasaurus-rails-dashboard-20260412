class AddTimeZoneToTherapists < ActiveRecord::Migration[8.1]
  def change
    add_column :therapists, :time_zone, :string
  end
end
