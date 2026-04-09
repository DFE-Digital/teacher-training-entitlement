class AddPreviousApplicationIdToApplications < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :applications, :superceding_application, index: { algorithm: :concurrently }
  end
end
