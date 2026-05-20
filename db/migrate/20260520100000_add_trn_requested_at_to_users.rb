class AddTrnRequestedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :trn_requested_at, :datetime
  end
end
