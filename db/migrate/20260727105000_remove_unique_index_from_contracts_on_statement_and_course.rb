class RemoveUniqueIndexFromContractsOnStatementAndCourse < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :contracts,
                 name: :index_contracts_on_statement_id_and_course_id,
                 algorithm: :concurrently
  end
end
