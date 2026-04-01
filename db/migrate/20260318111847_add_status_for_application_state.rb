class AddStatusForApplicationState < ActiveRecord::Migration[8.1]
  def change
    add_column :application_states, :status, :enum, enum_type: "application_statuses", null: true
  end
end
