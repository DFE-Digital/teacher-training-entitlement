class AddCourseForeignKeyToMilestones < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :milestones, :courses, validate: false
  end
end
