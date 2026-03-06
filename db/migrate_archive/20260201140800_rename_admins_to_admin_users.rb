class RenameAdminsToAdminUsers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured { rename_table :admins, :admin_users }
  end
end
