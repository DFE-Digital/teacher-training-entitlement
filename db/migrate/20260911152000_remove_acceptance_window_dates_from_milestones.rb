class RemoveAcceptanceWindowDatesFromMilestones < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :milestones, :acceptance_window_start_date, :date
      remove_column :milestones, :acceptance_window_end_date, :date
    end
  end
end
