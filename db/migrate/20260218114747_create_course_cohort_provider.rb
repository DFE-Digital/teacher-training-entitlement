class CreateCourseCohortProvider < ActiveRecord::Migration[8.1]
  def change
    create_table :course_cohort_providers do |t|
      t.references :course_cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.timestamps
    end
  end
end
