class RemoveTeacherCatchmentCountryFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :applications, :teacher_catchment_country, :text }
  end
end
