class AddActiveToLeadProvider < ActiveRecord::Migration[8.1]
  def change
    add_column :lead_providers, :active, :boolean, default: true
  end
end
