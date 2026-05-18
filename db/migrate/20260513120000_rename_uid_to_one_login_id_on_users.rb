class RenameUidToOneLoginIdOnUsers < ActiveRecord::Migration[8.0]
  def change
    safety_assured { rename_column :users, :uid, :one_login_id }
  end
end
