class DropLastVerifiedExpiresAtFromUserCredentials < ActiveRecord::Migration[8.1]
  def up
    # Pre-launch cleanup: wipe any stale credential rows so the new
    # month-precision expiration + grace-period logic starts clean.
    execute "DELETE FROM user_credentials"

    remove_column :user_credentials, :last_verified_expires_at
  end

  def down
    add_column :user_credentials, :last_verified_expires_at, :datetime
  end
end
