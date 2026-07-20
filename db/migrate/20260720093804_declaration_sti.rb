class DeclarationSti < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :declarations, :type, :string
    add_index :declarations, :type, algorithm: :concurrently
    # reference to paid declaration that triggered the clawback declaration
    add_reference :declarations, :paid_declaration, null: true, index: { algorithm: :concurrently }
    add_reference :declarations, :clawback_declaration, null: true, index: { algorithm: :concurrently }
  end
end
