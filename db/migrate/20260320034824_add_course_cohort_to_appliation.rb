class AddCourseCohortToAppliation < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :applications, :course_cohort, index: { algorithm: :concurrently }

    add_index :applications, %i[user_id course_cohort_id], unique: true, algorithm: :concurrently
    safety_assured do
      remove_column :applications, :schedule_id, :bigint
      remove_column :applications, :cohort_id, :bigint
      remove_column :applications, :course_id, :bigint
    end
  end
end
