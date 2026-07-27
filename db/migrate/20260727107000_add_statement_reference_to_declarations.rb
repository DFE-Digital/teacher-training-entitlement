class AddStatementReferenceToDeclarations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :declarations, :statement, index: { algorithm: :concurrently }
    add_foreign_key :declarations, :statements, validate: false
  end
end
