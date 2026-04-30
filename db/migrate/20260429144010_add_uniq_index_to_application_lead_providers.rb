class AddUniqIndexToApplicationLeadProviders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :application_lead_providers,
              %i[application_id lead_provider_id],
              unique: true,
              algorithm: :concurrently
  end
end
