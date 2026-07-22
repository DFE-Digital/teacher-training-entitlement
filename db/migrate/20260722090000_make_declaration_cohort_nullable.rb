class MakeDeclarationCohortNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :declarations, :cohort_id, true
  end
end
