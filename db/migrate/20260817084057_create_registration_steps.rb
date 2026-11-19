class CreateRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_steps do |t|
      t.references :registration_journey, null: false, foreign_key: true
      t.string :name
      t.jsonb :config, null: false, default: {}
      t.string :type
      t.string :slug
      t.string :redirect_path
      t.string :redirect_state_store_key
      t.string :state_store_key
      t.string :answer_display_name
      t.boolean :display_on_check_answers, null: false, default: true

      t.timestamps

      t.references :previous_step,
                   foreign_key: { to_table: :registration_steps, on_delete: :nullify }
      t.references :branch_join_step,
                   foreign_key: { to_table: :registration_steps, on_delete: :nullify }
      t.boolean :requires_answer, null: false, default: false
      t.string :required_answer_message
    end
  end
end
