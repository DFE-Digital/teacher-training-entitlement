class DropCourseCohorts < ActiveRecord::Migration[8.0]
  def change
    drop_table :course_cohorts do |t|
      t.references :cohort, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.uuid :ecf_id, default: -> { "gen_random_uuid()" }, null: false
      t.references :schedule
      t.timestamps

      t.index %i[course_id cohort_id], unique: true
      t.index :ecf_id, unique: true
    end
  end
end
