class AddUniqueIndexToMilestonesOnCourseCohortAndDeclarationType < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :milestones,
              %i[course_cohort_id declaration_type],
              unique: true,
              algorithm: :concurrently
  end
end
