class AddOrderToRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_steps, :order, :integer
  end
end
