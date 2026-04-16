class AddTypeToApplicationEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :application_events, :type, :string
    add_index :application_events, :type, algorithm: :concurrently
  end
end
