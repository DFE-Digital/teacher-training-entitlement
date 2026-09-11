class MakeMilestoneCourseCohortOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :milestones, :course_cohort_id, true
  end
end
