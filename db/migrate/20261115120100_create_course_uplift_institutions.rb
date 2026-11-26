class CreateCourseUpliftInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :course_uplift_institutions do |t|
      t.references :course, null: false, foreign_key: true, index: false
      t.references :institution, null: false, foreign_key: true, index: true
      t.timestamps
    end

    add_index :course_uplift_institutions, %i[course_id institution_id], unique: true
  end
end
