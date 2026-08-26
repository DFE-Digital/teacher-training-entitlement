class CreateRegistrationTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_templates do |t|
      t.string :name
      t.text :description
      t.string :template_generating_service_class
      t.string :service_class

      t.timestamps
    end
  end
end
