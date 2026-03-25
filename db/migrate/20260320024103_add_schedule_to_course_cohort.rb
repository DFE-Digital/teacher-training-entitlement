class AddScheduleToCourseCohort < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :course_cohorts, :schedule, index: { algorithm: :concurrently }
  end
end
