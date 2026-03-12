class AddApplicationStiColumn < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :applications, :type, :string
    add_index :applications, :type, algorithm: :concurrently
    Application.update_all(type: "ReceptionApplication")
  end
end
