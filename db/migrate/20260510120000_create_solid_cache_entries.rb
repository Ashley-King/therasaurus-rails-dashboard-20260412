class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cache_entries, id: :bigint do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 512.megabytes, null: false
      t.datetime :created_at, null: false
      t.bigint :key_hash, null: false
      t.integer :byte_size, null: false

      t.index :byte_size
      t.index :key_hash, unique: true
      t.index [ :key_hash, :byte_size ]
    end
  end
end
