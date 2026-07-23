class AddDatesToCourseCohorts < ActiveRecord::Migration[8.1]
  def change
    add_column :course_cohorts, :registration_starts_at, :date
    add_column :course_cohorts, :registration_ends_at, :date
    add_column :course_cohorts, :training_starts_at, :date
    add_column :course_cohorts, :training_ends_at, :date
  end
end
