class AddCohortRegistrationDates < ActiveRecord::Migration[8.1]
  def change
    add_column :cohorts, :registration_starts_at, :date
    add_column :cohorts, :registration_ends_at, :date
    safety_assured do
      remove_column :cohorts, :registration_start_date, :datetime
    end
  end
end
