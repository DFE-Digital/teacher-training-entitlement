class AddNameToPolicyPeriods < ActiveRecord::Migration[7.1]
  def change
    add_column :policy_periods, :name, :string
  end
end
