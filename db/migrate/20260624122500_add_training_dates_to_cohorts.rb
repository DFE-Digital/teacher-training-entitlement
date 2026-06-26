# frozen_string_literal: true

class AddTrainingDatesToCohorts < ActiveRecord::Migration[8.0]
  def up
    add_column :cohorts, :training_starts_at, :date unless column_exists?(:cohorts, :training_starts_at)
    add_column :cohorts, :training_ends_at, :date unless column_exists?(:cohorts, :training_ends_at)

    safety_assured do
      execute <<~SQL.squish
        UPDATE cohorts
        SET training_starts_at = schedules.training_starts_at,
            training_ends_at = schedules.training_ends_at
        FROM schedules
        WHERE schedules.cohort_id = cohorts.id
      SQL
    end
  end

  def down
    remove_column :cohorts, :training_ends_at if column_exists?(:cohorts, :training_ends_at)
    remove_column :cohorts, :training_starts_at if column_exists?(:cohorts, :training_starts_at)
  end
end
