class AddYearToTherapistContinuingEducation < ActiveRecord::Migration[8.1]
  def change
    add_column :therapist_continuing_education, :year, :integer
  end
end
