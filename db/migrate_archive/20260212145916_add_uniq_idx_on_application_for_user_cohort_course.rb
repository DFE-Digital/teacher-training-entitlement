class AddUniqIdxOnApplicationForUserCohortCourse < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :applications,
              %i[user_id cohort_id course_id],
              unique: true,
              where: "lead_provider_approval_status <> 'rejected'",
              algorithm: :concurrently
  end
end
