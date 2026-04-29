class AddBirthDateToTherapists < ActiveRecord::Migration[8.1]
  def change
    add_column :therapists, :birth_date, :date
  end
end
