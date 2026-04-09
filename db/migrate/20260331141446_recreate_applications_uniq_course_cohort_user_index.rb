class RecreateApplicationsUniqCourseCohortUserIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :applications, # rubocop:disable Rails/ReversibleMigration
                 name: "index_applications_on_user_id_and_course_cohort_id"

    add_index :applications,
              %i[user_id course_cohort_id],
              unique: true,
              where: "status NOT IN ('rejected', 'superceded')",
              algorithm: :concurrently
  end
end
