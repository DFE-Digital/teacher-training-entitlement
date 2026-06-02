class AddAssignmentTimestampToApplicationLeadProviderTable < ActiveRecord::Migration[8.1]
  def change
    add_column :application_lead_providers, :assigned_at, :datetime
    add_column :application_lead_providers, :unassigned_at, :datetime
  end
end
