class AddPolicyPeriodForeignKeyToCourseCohorts < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :course_cohorts, :policy_periods, validate: false
  end
end
