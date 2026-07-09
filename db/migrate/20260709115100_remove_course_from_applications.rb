# frozen_string_literal: true

class RemoveCourseFromApplications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :applications, name: "index_applications_on_course_id", algorithm: :concurrently if index_exists?(:applications, :course_id, name: "index_applications_on_course_id")

    safety_assured do
      remove_column :applications, :course_id if column_exists?(:applications, :course_id)
    end
  end

  def down
    add_reference :applications, :course, index: { algorithm: :concurrently } unless column_exists?(:applications, :course_id)

    safety_assured do
      execute <<~SQL.squish
        UPDATE applications
        SET course_id = cohorts.course_id
        FROM cohorts
        WHERE applications.cohort_id = cohorts.id
      SQL
    end
  end
end
