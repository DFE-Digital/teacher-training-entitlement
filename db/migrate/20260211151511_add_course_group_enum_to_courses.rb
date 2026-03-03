class AddCourseGroupEnumToCourses < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      create_enum :course_group, %w[reception send]
      add_column :courses, :course_group, :enum, enum_type: "course_group"
    end

    Course.update_all(course_group: "reception")
  end
end
