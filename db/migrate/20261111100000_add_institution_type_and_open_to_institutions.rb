class AddInstitutionTypeAndOpenToInstitutions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :institutions, :institution_type, :string
    add_column :institutions, :open, :boolean
    add_index :institutions, :institution_type, algorithm: :concurrently
  end
end
