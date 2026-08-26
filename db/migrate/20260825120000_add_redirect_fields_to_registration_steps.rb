class AddRedirectFieldsToRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_steps, :redirect_path, :string
    add_column :registration_steps, :redirect_state_store_key, :string
  end
end
