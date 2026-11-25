class MigrateCourseGroupValuesToNpd < ActiveRecord::Migration[8.1]
  def up
    Course.where(course_group: "reception").update_all(course_group: "npd")
    Statement.where(course_group: "reception").update_all(course_group: "npd")
  end

  def down
    Course.where(course_group: "npd").update_all(course_group: "reception")
    Statement.where(course_group: "npd").update_all(course_group: "reception")
  end
end
