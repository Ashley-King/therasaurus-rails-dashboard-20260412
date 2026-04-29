class AddIdentityVisibilityFlagsToTherapists < ActiveRecord::Migration[8.1]
  def change
    add_column :therapists, :show_pronouns_on_profile, :boolean, default: false, null: false
    add_column :therapists, :show_genders_on_profile, :boolean, default: false, null: false
    add_column :therapists, :show_race_ethnicities_on_profile, :boolean, default: false, null: false
  end
end
