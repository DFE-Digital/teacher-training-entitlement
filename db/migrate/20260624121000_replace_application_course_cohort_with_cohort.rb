# frozen_string_literal: true

class ReplaceApplicationCourseCohortWithCohort < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_reference :applications, :cohort, index: { algorithm: :concurrently } unless column_exists?(:applications, :cohort_id)

    safety_assured do
      execute <<~SQL.squish
        UPDATE applications
        SET cohort_id = course_cohorts.cohort_id
        FROM course_cohorts
        WHERE applications.course_cohort_id = course_cohorts.id
      SQL
    end

    add_index :applications,
              %i[user_id cohort_id],
              unique: true,
              algorithm: :concurrently,
              name: "index_applications_on_user_id_and_cohort_id",
              if_not_exists: true

    remove_index :applications, name: "index_applications_on_user_id_and_course_cohort_id", algorithm: :concurrently if index_exists?(:applications, %i[user_id course_cohort_id], name: "index_applications_on_user_id_and_course_cohort_id")
    remove_index :applications, name: "index_applications_on_course_cohort_id", algorithm: :concurrently if index_exists?(:applications, :course_cohort_id, name: "index_applications_on_course_cohort_id")

    safety_assured do
      remove_column :applications, :course_cohort_id if column_exists?(:applications, :course_cohort_id)
    end
  end

  def down
    add_reference :applications, :course_cohort, index: { algorithm: :concurrently } unless column_exists?(:applications, :course_cohort_id)

    safety_assured do
      execute <<~SQL.squish
        UPDATE applications
        SET course_cohort_id = course_cohorts.id
        FROM cohorts
        INNER JOIN course_cohorts
          ON course_cohorts.cohort_id = cohorts.id
          AND course_cohorts.course_id = cohorts.course_id
        WHERE applications.cohort_id = cohorts.id
      SQL
    end

    add_index :applications,
              %i[user_id course_cohort_id],
              unique: true,
              algorithm: :concurrently,
              name: "index_applications_on_user_id_and_course_cohort_id",
              if_not_exists: true

    remove_index :applications, name: "index_applications_on_user_id_and_cohort_id", algorithm: :concurrently if index_exists?(:applications, %i[user_id cohort_id], name: "index_applications_on_user_id_and_cohort_id")
    remove_index :applications, name: "index_applications_on_cohort_id", algorithm: :concurrently if index_exists?(:applications, :cohort_id, name: "index_applications_on_cohort_id")

    safety_assured do
      remove_column :applications, :cohort_id if column_exists?(:applications, :cohort_id)
    end
  end
end
