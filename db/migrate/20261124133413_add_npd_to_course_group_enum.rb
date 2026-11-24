class AddNpdToCourseGroupEnum < ActiveRecord::Migration[8.1]
  def change
    safety_assured { execute "ALTER TYPE course_group ADD VALUE 'npd' before 'reception'" } # rubocop:disable Rails/ReversibleMigration
  end
end
