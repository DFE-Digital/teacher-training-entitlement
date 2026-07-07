class RemoveUniqueIndexFromApplicationLeadProviders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :application_lead_providers,
                 name: "idx_on_application_id_lead_provider_id_f38fa4893f",
                 algorithm: :concurrently
  end

  def down
    add_index :application_lead_providers,
              %i[application_id lead_provider_id],
              unique: true,
              name: "idx_on_application_id_lead_provider_id_f38fa4893f",
              algorithm: :concurrently
  end
end
