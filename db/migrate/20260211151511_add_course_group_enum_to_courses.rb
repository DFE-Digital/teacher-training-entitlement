class AddCourseGroupEnumToCourses < ActiveRecord::Migration[8.1]
  def change
    rename_column :courses, :course_group_name, :course_group

    Course.update_all(course_group: "reception")
  end
end
