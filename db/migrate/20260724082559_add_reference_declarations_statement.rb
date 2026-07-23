class AddReferenceDeclarationsStatement < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :declarations, :statement, null: true, index: {algorithm: :concurrently}
  end
end
