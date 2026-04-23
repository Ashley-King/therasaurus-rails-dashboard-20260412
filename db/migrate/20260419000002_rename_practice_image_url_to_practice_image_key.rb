class RenamePracticeImageUrlToPracticeImageKey < ActiveRecord::Migration[8.1]
  def up
    # Pre-launch: storage format changes from full URL to R2 object key.
    # The column holds a key like "profiles/<uuid>/<timestamp>-<hash>.jpg"
    # instead of a full public URL. The URL is built in
    # Therapist#practice_image_url from R2_PUBLIC_URL + key. Wiping
    # authorized by project owner — no real users.
    execute "UPDATE therapists SET practice_image_url = NULL WHERE practice_image_url IS NOT NULL"
    rename_column :therapists, :practice_image_url, :practice_image_key
  end

  def down
    rename_column :therapists, :practice_image_key, :practice_image_url
  end
end
