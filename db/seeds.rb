# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

[
  {
    code: "US",
    name: "United States",
    active: true,
    default_locale: "en",
    currency_code: "USD",
    postal_code_label: "ZIP code",
    administrative_area_label: "State"
  },
  {
    code: "CA",
    name: "Canada",
    active: false,
    default_locale: "en-CA",
    currency_code: "CAD",
    postal_code_label: "Postal code",
    administrative_area_label: "Province"
  },
  {
    code: "MX",
    name: "Mexico",
    active: false,
    default_locale: "es-MX",
    currency_code: "MXN",
    postal_code_label: "Postal code",
    administrative_area_label: "State"
  }
].each do |attributes|
  country = Country.find_or_initialize_by(code: attributes.fetch(:code))
  country.update!(attributes)
end
