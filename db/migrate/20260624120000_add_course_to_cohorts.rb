# frozen_string_literal: true

class AddCourseToCohorts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :cohorts, :course, index: { algorithm: :concurrently } unless column_exists?(:cohorts, :course_id)

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL.squish
            UPDATE cohorts
            SET course_id = cohort_courses.course_id
            FROM (
              SELECT cohort_id, MIN(course_id) AS course_id
              FROM course_cohorts
              GROUP BY cohort_id
              HAVING COUNT(DISTINCT course_id) = 1
            ) cohort_courses
            WHERE cohorts.id = cohort_courses.cohort_id
          SQL
        end
      end
    end
  end
end
