class ValidateInstitutionForeignKeyOnApplications < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :applications, :institutions
  end
end
