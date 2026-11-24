class RenameUsersToTeachers < ActiveRecord::Migration[8.1]
  def up
    # safety_assured justification: the previous release queries "users" and
    # "user_id", so this must be deployed during a maintenance window with
    # traffic on the fail-over page and workers scaled to zero, not as a
    # rolling deploy alongside old pods.
    safety_assured do
      rename_table :users, :teachers
      rename_column :teachers, :notify_user_for_future_reg, :notify_teacher_for_future_reg
      rename_column :applications, :user_id, :teacher_id
      rename_column :participant_id_changes, :user_id, :teacher_id

      execute "UPDATE versions SET item_type = 'Teacher' WHERE item_type = 'User'"
      execute <<~SQL
        UPDATE flipper_gates
        SET value = 'Teacher;' || substring(value FROM #{'User;'.length + 1})
        WHERE key = 'actors' AND value LIKE 'User;%'
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL
        UPDATE flipper_gates
        SET value = 'User;' || substring(value FROM #{'Teacher;'.length + 1})
        WHERE key = 'actors' AND value LIKE 'Teacher;%'
      SQL
      execute "UPDATE versions SET item_type = 'User' WHERE item_type = 'Teacher'"

      rename_column :participant_id_changes, :teacher_id, :user_id
      rename_column :applications, :teacher_id, :user_id
      rename_column :teachers, :notify_teacher_for_future_reg, :notify_user_for_future_reg
      rename_table :teachers, :users
    end
  end
end
