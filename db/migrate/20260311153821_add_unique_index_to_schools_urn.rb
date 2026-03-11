class AddUniqueIndexToSchoolsUrn < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :schools, :urn, algorithm: :concurrently, if_exists: true
    add_index :schools, :urn, unique: true, algorithm: :concurrently
  end
end
