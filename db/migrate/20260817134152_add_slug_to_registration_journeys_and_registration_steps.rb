class AddSlugToRegistrationJourneysAndRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_journeys, :slug, :string
    add_column :registration_steps, :slug, :string
  end
end
