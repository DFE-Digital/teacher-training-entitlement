class RemoveLeadProviderIdFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :lead_provider_id, :bigint }
  end
end
