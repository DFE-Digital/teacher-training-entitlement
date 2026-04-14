class AlterApplicationEcfIdUniqIdx < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :applications, # rubocop:disable Rails/ReversibleMigration
                 name: "index_applications_on_ecf_id"

    add_index :applications,
              %i[ecf_id lead_provider_id],
              unique: true,
              algorithm: :concurrently
  end
end
