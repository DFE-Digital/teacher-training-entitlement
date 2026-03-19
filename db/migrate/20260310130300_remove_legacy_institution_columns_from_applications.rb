class RemoveLegacyInstitutionColumnsFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :applications, :school_id, :bigint
      remove_column :applications, :private_childcare_provider_id, :bigint
      remove_column :applications, :DEPRECATED_school_urn, :string
      remove_column :applications, :DEPRECATED_private_childcare_provider_urn, :string
    end
  end
end
