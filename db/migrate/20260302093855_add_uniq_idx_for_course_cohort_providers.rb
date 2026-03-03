class AddUniqIdxForCourseCohortProviders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :course_cohort_providers, %i[course_cohort_id lead_provider_id], unique: true, algorithm: :concurrently
  end
end
