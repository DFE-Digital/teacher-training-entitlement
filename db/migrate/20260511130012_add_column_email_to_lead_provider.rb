class AddColumnEmailToLeadProvider < ActiveRecord::Migration[8.1]
  def change
    add_column :lead_providers, :email, :string
  end
end
