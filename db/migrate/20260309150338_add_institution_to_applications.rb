class AddInstitutionToApplications < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :applications, :institution, index: { algorithm: :concurrently }
  end
end
