class AddScheduleTrainingDates < ActiveRecord::Migration[8.1]
  def change
    add_column :schedules, :training_starts_at, :date
    add_column :schedules, :training_ends_at, :date
    safety_assured do
      remove_column :schedules, :applies_from, :date
      remove_column :schedules, :applies_to, :date
    end
  end
end
