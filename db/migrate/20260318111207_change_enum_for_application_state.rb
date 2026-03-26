class ChangeEnumForApplicationState < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :application_states, :state, :enum, enum_type: "application_state_states" }
    drop_enum :application_state_states
  end
end
