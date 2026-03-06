class CreateCourseCohort < ActiveRecord::Migration[8.1]
  def change
    create_table :course_cohorts do |t|
      t.references :course, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true
      t.timestamps
    end
  end
end
