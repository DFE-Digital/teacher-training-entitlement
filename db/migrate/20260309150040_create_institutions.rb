class CreateInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :institutions do |t|
      t.string :institutionable_type, null: false
      t.bigint :institutionable_id, null: false
      t.string :name
      t.string :address_1
      t.string :address_2
      t.string :address_3
      t.string :town
      t.string :county
      t.string :postcode
      t.string :postcode_without_spaces
      t.string :region
      t.timestamps

      t.index %i[institutionable_type institutionable_id], unique: true
    end

    safety_assured do
      # Remove duplicate columns now in Institution (schools)
      remove_column :schools, :name, :text
      remove_column :schools, :address_1, :text
      remove_column :schools, :address_2, :text
      remove_column :schools, :address_3, :text
      remove_column :schools, :town, :text
      remove_column :schools, :county, :text
      remove_column :schools, :postcode, :text
      remove_column :schools, :postcode_without_spaces, :text
      remove_column :schools, :region, :text
      # Remove unused columns (schools)
      remove_column :schools, :country, :text
      remove_column :schools, :easting, :integer
      remove_column :schools, :northing, :integer
      remove_column :schools, :establishment_number, :text

      # Remove duplicate columns now in Institution (private_childcare_providers)
      remove_column :private_childcare_providers, :provider_name, :text
      remove_column :private_childcare_providers, :address_1, :text
      remove_column :private_childcare_providers, :address_2, :text
      remove_column :private_childcare_providers, :address_3, :text
      remove_column :private_childcare_providers, :town, :text
      remove_column :private_childcare_providers, :postcode, :text
      remove_column :private_childcare_providers, :postcode_without_spaces, :text
      remove_column :private_childcare_providers, :region, :text
      remove_column :private_childcare_providers, :ofsted_region, :text
      # Remove unused columns (private_childcare_providers)
      remove_column :private_childcare_providers, :places, :integer
      remove_column :private_childcare_providers, :registered_person_name, :text
      remove_column :private_childcare_providers, :registered_person_urn, :text
      remove_column :private_childcare_providers, :registration_date, :text
      remove_column :private_childcare_providers, :provider_status, :text

      # Remove duplicate columns now in Institution (local_authorities)
      remove_column :local_authorities, :name, :text
      remove_column :local_authorities, :address_1, :text
      remove_column :local_authorities, :address_2, :text
      remove_column :local_authorities, :address_3, :text
      remove_column :local_authorities, :town, :text
      remove_column :local_authorities, :county, :text
      remove_column :local_authorities, :postcode, :text
      remove_column :local_authorities, :postcode_without_spaces, :text
    end
  end
end
