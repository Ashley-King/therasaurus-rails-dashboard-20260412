class AddTelehealthParkingPersonalStatementToTherapists < ActiveRecord::Migration[8.1]
  def change
    add_column :therapists, :telehealth_platform, :string
    add_column :therapists, :parking_transit_notes, :text
    add_column :therapists, :personal_statement, :text
  end
end
