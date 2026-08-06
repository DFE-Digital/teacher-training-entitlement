class UpdateStatement < ActiveRecord::Migration[8.1]
  def change
    create_enum :statements_frequency_types, %w[monthly]

    add_column :statements, :start_date, :date unless column_exists?(:statements, :start_date)
    add_column :statements, :frequency, :enum, enum_type: :statements_frequency_types unless column_exists?(:statements, :frequency)

    change_column_null :statements, :cohort_id, true
    change_column_null :statements, :month, true
    change_column_null :statements, :year, true
  end
end
