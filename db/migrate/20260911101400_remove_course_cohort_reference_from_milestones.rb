class RemoveCourseCohortReferenceFromMilestones < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :milestones,
                 %i[course_cohort_id declaration_type],
                 algorithm: :concurrently,
                 if_exists: true

    remove_foreign_key :milestones, :course_cohorts if foreign_key_exists?(:milestones, :course_cohorts)
    remove_index :milestones, :course_cohort_id, algorithm: :concurrently if index_exists?(:milestones, :course_cohort_id)
    safety_assured { remove_column :milestones, :course_cohort_id if column_exists?(:milestones, :course_cohort_id) }
  end

  def down
    add_reference :milestones, :course_cohort, index: { algorithm: :concurrently }, foreign_key: true

    add_index :milestones,
              %i[course_cohort_id declaration_type],
              unique: true,
              algorithm: :concurrently
  end
end
