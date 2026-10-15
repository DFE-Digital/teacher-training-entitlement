class AddRegistrationDataToApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :applications, :registration_data, :jsonb, default: {}, null: false
  end
end
