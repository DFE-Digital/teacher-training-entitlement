class AddArchivedAtToDeliveryPartnerships < ActiveRecord::Migration[8.1]
  def change
    add_column :delivery_partnerships, :archived_at, :datetime
  end
end
