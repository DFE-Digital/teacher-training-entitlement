class CreateRegistrationJourneys < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_journeys do |t|
      t.string :name
      t.string :funding_type

      t.timestamps
    end
  end
end
