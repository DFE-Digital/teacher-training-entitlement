class AddActiveToApplicationLeadProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :application_lead_providers, :current, :boolean, default: false
  end
end
