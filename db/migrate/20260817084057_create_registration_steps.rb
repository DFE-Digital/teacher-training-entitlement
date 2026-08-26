class CreateRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_steps do |t|
      t.references :registration_journey, null: false, foreign_key: true
      t.string :name
      t.jsonb :config, null: false, default: {}
      t.string :type

      t.timestamps
    end
  end
end
