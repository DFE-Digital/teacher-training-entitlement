class RemoveTeacherCatchmentAndWorkSettingFromApplications < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      # keep work_setting answers that are only held in the column
      execute <<~SQL
        UPDATE applications
        SET registration_data = jsonb_set(registration_data, '{work_setting}', to_jsonb(work_setting))
        WHERE work_setting IS NOT NULL
          AND NULLIF(registration_data->>'work_setting', '') IS NULL
      SQL

      remove_column :applications, :teacher_catchment
      remove_column :applications, :work_setting
    end
  end

  def down
    safety_assured do
      add_column :applications, :teacher_catchment, :text
      add_column :applications, :work_setting, :text

      execute <<~SQL
        UPDATE applications
        SET work_setting = registration_data->>'work_setting',
            teacher_catchment = registration_data->>'teacher_catchment'
      SQL
    end
  end
end
