class AddGeographyToInstitutions < ActiveRecord::Migration[8.1]
  def change
    add_column :institutions, :alpha3_country_code, :string, limit: 3
    add_column :institutions, :subdivision_code, :string, limit: 3
  end
end
