class AddPreviousApplicationIdFkToApplications < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :applications, :applications,
                    column: :superceding_application_id,
                    validate: false
  end
end
