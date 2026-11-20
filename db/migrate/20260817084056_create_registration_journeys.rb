class CreateRegistrationJourneys < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_journeys do |t|
      t.string :name
      t.string :slug
      t.references :course

      t.timestamps
    end
  end
end
