class AddInstitutionForeignKeyToApplications < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :applications, :institutions, validate: false
  end
end
