class RemoveFundingTypeFromRegistrationJourneys < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :registration_journeys, :funding_type, :string }
  end
end
