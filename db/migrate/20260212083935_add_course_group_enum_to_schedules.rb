class AddCourseGroupEnumToSchedules < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_column :schedules, :course_group, :enum, enum_type: "course_group"
    end

    Schedule.update_all(course_group: "reception")
  end
end
