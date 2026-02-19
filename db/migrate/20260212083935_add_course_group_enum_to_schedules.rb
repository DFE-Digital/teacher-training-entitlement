class AddCourseGroupEnumToSchedules < ActiveRecord::Migration[8.1]
  def change
    add_column :schedules, :course_group, :string

    Schedule.update_all(course_group: "reception")
  end
end
