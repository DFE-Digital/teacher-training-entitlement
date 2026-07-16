class AddCourseCohortReferenceToMilestones < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      # We're ok here because we don't have any milestones.
      # rubocop:disable Rails/NotNullColumn
      add_reference :milestones, :course_cohort, null: false, index: { algorithm: :concurrently }, foreign_key: true
      # rubocop:enable Rails/NotNullColumn
    end
  end

  def down
    remove_foreign_key :milestones, :course_cohorts if foreign_key_exists?(:milestones, :course_cohorts)
    remove_index :milestones, :course_cohort_id, algorithm: :concurrently if index_exists?(:milestones, :course_cohort_id)
    remove_column :milestones, :course_cohort_id if column_exists?(:milestones, :course_cohort_id)
  end
end
