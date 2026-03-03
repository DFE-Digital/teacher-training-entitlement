class DropCourseGroup < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :courses, :course_group_id, :bigint
      remove_column :schedules, :course_group_id, :bigint
      drop_table :course_groups # rubocop:disable Rails/ReversibleMigration
    end
  end
end
