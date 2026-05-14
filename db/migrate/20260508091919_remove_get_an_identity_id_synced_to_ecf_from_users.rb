class RemoveGetAnIdentityIdSyncedToEcfFromUsers < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :users, :get_an_identity_id_synced_to_ecf, :boolean, default: false }
  end
end
