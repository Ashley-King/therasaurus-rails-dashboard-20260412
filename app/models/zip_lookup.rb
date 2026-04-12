class ZipLookup < ApplicationRecord
  self.table_name = "zip_lookups"

  def self.geocode(zip:, state_id:)
    find_by(zip: zip, state_id: state_id)
  end
end
