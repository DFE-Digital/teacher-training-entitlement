class AddIndexToApplicationStatus < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :applications, :status, algorithm: :concurrently
    add_index :application_states, :status, algorithm: :concurrently
  end
end
