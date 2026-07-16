class AddRecruitmentTargetToCourseCohortProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :course_cohort_providers, :recruitment_target, :integer
  end
end
