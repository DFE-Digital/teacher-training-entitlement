class MakeContractReferencesNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :contracts, :statement_id, true
    change_column_null :contracts, :course_id, true
    change_column_null :contracts, :contract_template_id, true
  end
end
