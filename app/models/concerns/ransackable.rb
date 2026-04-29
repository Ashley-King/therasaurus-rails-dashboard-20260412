# Allows every column and association to be searchable via Ransack.
# Safe today because no model holds secrets/tokens (Supabase owns auth).
# If a sensitive column is ever added, override `ransackable_attributes`
# on that single model to exclude it.
module Ransackable
  extend ActiveSupport::Concern

  class_methods do
    def ransackable_attributes(_auth_object = nil)
      column_names
    end

    def ransackable_associations(_auth_object = nil)
      reflect_on_all_associations.map { |a| a.name.to_s }
    end
  end
end
