class UpdateStatement < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_index :statements, :cohort_id if index_exists?(:statements, :cohort_id)

      remove_column :statements, :cohort_id, :bigint if column_exists?(:statements, :cohort_id)
      remove_column :statements, :month, :integer if column_exists?(:statements, :month)
      remove_column :statements, :year, :integer if column_exists?(:statements, :year)
    end

    create_enum :statements_frequency_types, %w[monthly]

    add_column :statements, :start_date, :date unless column_exists?(:statements, :start_date)
    add_column :statements, :frequency, :enum, enum_type: :statements_frequency_types unless column_exists?(:statements, :frequency)

    unless index_exists?(:statements, %i[lead_provider_id start_date frequency])
      add_index :statements, %i[lead_provider_id start_date frequency],
                UNIQUE: true,
                name: "index_statements_on_lead_provider_id_start_date_frequency",
                algorithm: :concurrently
    end
  end
end
