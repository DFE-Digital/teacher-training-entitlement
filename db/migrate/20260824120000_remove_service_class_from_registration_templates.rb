class RemoveServiceClassFromRegistrationTemplates < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :registration_templates, :service_class, :string }
  end
end
