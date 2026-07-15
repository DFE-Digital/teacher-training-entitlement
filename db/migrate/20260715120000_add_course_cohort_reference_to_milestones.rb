class AddCourseCohortReferenceToMilestones < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    unless column_exists?(:milestones, :course_cohort_id)
      add_reference :milestones, :course_cohort, null: true, foreign_key: false, index: { algorithm: :concurrently }
    end

    safety_assured do
      execute <<~SQL.squish
        UPDATE milestones
        SET course_cohort_id = course_cohorts.id
        FROM course_cohorts
        WHERE course_cohorts.schedule_id = milestones.schedule_id
          AND course_cohort_id IS NULL
      SQL
    end

    safety_assured { change_column_null :milestones, :course_cohort_id, false }
    add_foreign_key :milestones, :course_cohorts, validate: false unless foreign_key_exists?(:milestones, :course_cohorts)
  end

  def down
    remove_foreign_key :milestones, :course_cohorts
    remove_index :milestones, :course_cohort_id, algorithm: :concurrently
    remove_column :milestones, :course_cohort_id
  end
end
