class RemoveUniqueIndexFromCourseCohortsOnCourseAndCohort < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :course_cohorts,
                 name: :index_course_cohorts_on_course_id_and_cohort_id,
                 algorithm: :concurrently
  end
end
