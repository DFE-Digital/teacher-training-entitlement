class AddLeadProviderReferenceToContracts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :contracts, :lead_provider, index: { algorithm: :concurrently } unless column_exists?(:contracts, :lead_provider_id)
    add_foreign_key :contracts, :lead_providers, validate: false unless foreign_key_exists?(:contracts, :lead_providers)

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL.squish
            UPDATE contracts
            SET lead_provider_id = statements.lead_provider_id
            FROM statements
            WHERE contracts.statement_id = statements.id
          SQL
        end
      end
    end
  end
end
