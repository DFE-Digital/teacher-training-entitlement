class UpdateStatementTable < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_index :statements, :cohort_id if index_exists?(:statements, :cohort_id)

      remove_column :statements, :cohort_id, :bigint if column_exists?(:statements, :cohort_id)
      remove_column :statements, :month, :integer if column_exists?(:statements, :month)
      remove_column :statements, :year, :integer if column_exists?(:statements, :year)
    end

    unless index_exists?(:statements, %i[lead_provider_id start_date frequency])
      add_index :statements, %i[lead_provider_id start_date frequency],
                unique: true,
                name: "index_statements_on_lead_provider_id_start_date_frequency",
                algorithm: :concurrently
    end
  end
end
