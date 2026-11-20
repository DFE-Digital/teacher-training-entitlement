class AddStateStoreKeyToRegistrationStepAnswers < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_step_answers, :state_store_key, :string
  end
end
