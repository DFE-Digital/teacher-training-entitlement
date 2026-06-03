class RemoveTrnVerifiedFlagsFromUsers < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :users, :trn_verified, :boolean, default: false, null: false
      remove_column :users, :trn_auto_verified, :boolean, default: false
    end
  end
end
