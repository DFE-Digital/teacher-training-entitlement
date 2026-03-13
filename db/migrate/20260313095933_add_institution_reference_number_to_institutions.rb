class AddInstitutionReferenceNumberToInstitutions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :institutions, :institution_reference_number, :string
    add_index :institutions, :institution_reference_number, algorithm: :concurrently
  end
end
