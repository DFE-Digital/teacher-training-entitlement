class RemoveUrnColumnsFromSubclasses < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :schools, :urn, :text
      remove_column :private_childcare_providers, :provider_urn, :string
      remove_column :local_authorities, :ukprn, :text
    end
  end
end
