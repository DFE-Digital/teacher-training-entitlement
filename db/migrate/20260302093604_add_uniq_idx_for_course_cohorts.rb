class AddUniqIdxForCourseCohorts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :course_cohorts, %i[course_id cohort_id], unique: true, algorithm: :concurrently
  end
end
