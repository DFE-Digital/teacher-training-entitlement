class AddIndexToApplicationsEmail < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :applications, :email, algorithm: :concurrently
  end
end
