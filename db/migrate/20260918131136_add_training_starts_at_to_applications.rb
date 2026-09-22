class AddTrainingStartsAtToApplications < ActiveRecord::Migration[8.1]
  def up
    add_column :applications, :training_starts_at, :date

    safety_assured do
      execute <<~SQL.squish
        UPDATE applications
        SET training_starts_at = course_cohorts.training_starts_at
        FROM course_cohorts
        WHERE course_cohorts.id = applications.course_cohort_id
      SQL
    end
  end

  def down
    remove_column :applications, :training_starts_at
  end
end
