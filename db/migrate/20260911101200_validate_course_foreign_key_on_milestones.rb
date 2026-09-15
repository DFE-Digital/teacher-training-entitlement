class ValidateCourseForeignKeyOnMilestones < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :milestones, :courses
  end
end
