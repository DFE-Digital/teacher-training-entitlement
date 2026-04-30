class CreateApplicationLeadProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :application_lead_providers do |t|
      t.references :application
      t.references :lead_provider
      t.timestamps
    end
  end
end
