class RemoveTrainingStatus < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :training_status, :enum, enum_type: "application_state_states" }
  end
end
