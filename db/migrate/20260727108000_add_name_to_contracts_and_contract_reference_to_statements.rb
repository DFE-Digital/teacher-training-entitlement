class AddNameToContractsAndContractReferenceToStatements < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :contracts, :name, :string
    add_reference :statements, :contract, null: true, index: { algorithm: :concurrently }
  end
end
