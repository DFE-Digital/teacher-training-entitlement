class AddStatusToApplication < ActiveRecord::Migration[8.1]
  def change
    safety_assured { execute "ALTER TYPE application_statuses RENAME TO application_state_states;" } # rubocop:disable Rails/ReversibleMigration

    create_enum :application_statuses, %w[pending accepted started rejected completed deferred withdrawn]

    add_column :applications, :status, :enum, enum_type: "application_statuses", null: true
  end
end
