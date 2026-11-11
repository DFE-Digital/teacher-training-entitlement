class AllowNullCourseCohortOnDeliveryPartnerships < ActiveRecord::Migration[8.1]
  # Partnerships are now created at course level; course_cohort_id is kept
  # only until the backfill has run, then dropped in a later migration.
  def change
    change_column_null :delivery_partnerships, :course_cohort_id, true
  end
end
