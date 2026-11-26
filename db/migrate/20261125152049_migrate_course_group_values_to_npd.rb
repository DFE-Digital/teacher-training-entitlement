class MigrateCourseGroupValuesToNpd < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
        UPDATE courses SET course_group = 'npd' WHERE course_group = 'reception';
        UPDATE statements SET course_group = 'npd' WHERE course_group = 'reception';
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL
        UPDATE courses SET course_group = 'reception' WHERE course_group = 'npd';
        UPDATE statements SET course_group = 'reception' WHERE course_group = 'npd';
      SQL
    end
  end
end
