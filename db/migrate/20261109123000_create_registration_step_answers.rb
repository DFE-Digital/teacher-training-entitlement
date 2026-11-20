class CreateRegistrationStepAnswers < ActiveRecord::Migration[8.1]
  def up
    create_table :registration_step_answers do |t|
      t.bigint :registration_step_id, null: false
      t.bigint :next_step_id
      t.string :name
      t.string :value
      t.text :hint
      t.string :redirect_path
      t.string :redirect_state_store_key
      t.integer :position, null: false, default: 0

      t.timestamps

      t.index %i[registration_step_id position], name: "index_registration_step_answers_on_step_and_position"
      t.index :next_step_id
    end
  end

  def down
    drop_table :registration_step_answers
  end
end
