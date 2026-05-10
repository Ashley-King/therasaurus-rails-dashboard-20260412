class AddCountryRulesToCountries < ActiveRecord::Migration[8.1]
  COUNTRY_RULES = [
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
  ].freeze

  def up
    add_column :countries, :active, :boolean, null: false, default: false
    add_column :countries, :default_locale, :string, null: false, default: "en"
    add_column :countries, :currency_code, :string, null: false, default: "USD", limit: 3
    add_column :countries, :postal_code_label, :string, null: false, default: "Postal code"
    add_column :countries, :administrative_area_label, :string, null: false, default: "State"
    add_index :countries, :active

    seed_country_rules
  end

  def down
    remove_index :countries, :active
    remove_column :countries, :administrative_area_label
    remove_column :countries, :postal_code_label
    remove_column :countries, :currency_code
    remove_column :countries, :default_locale
    remove_column :countries, :active
  end

  private

  def seed_country_rules
    values = COUNTRY_RULES.map do |country|
      [
        quote(country[:code]),
        quote(country[:name]),
        quote(country[:active]),
        quote(country[:default_locale]),
        quote(country[:currency_code]),
        quote(country[:postal_code_label]),
        quote(country[:administrative_area_label])
      ].join(", ")
    end

    execute <<~SQL.squish
      INSERT INTO countries (
        code,
        name,
        active,
        default_locale,
        currency_code,
        postal_code_label,
        administrative_area_label,
        created_at,
        updated_at
      )
      VALUES #{values.map { |value| "(#{value}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" }.join(", ")}
      ON CONFLICT (code) DO UPDATE SET
        name = EXCLUDED.name,
        active = EXCLUDED.active,
        default_locale = EXCLUDED.default_locale,
        currency_code = EXCLUDED.currency_code,
        postal_code_label = EXCLUDED.postal_code_label,
        administrative_area_label = EXCLUDED.administrative_area_label,
        updated_at = CURRENT_TIMESTAMP
    SQL
  end
end
