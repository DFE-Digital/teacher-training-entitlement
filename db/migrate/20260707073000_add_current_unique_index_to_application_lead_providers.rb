class AddCurrentUniqueIndexToApplicationLeadProviders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :application_lead_providers,
              %i[lead_provider_id application_id],
              unique: true,
              where: "current = true",
              name: "idx_unique_current_application_lead_providers",
              algorithm: :concurrently
  end
end
