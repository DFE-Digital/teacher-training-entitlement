class RemoveAcceptedAtFromApplications < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :applications, :accepted_at, :datetime
    end
  end
end
