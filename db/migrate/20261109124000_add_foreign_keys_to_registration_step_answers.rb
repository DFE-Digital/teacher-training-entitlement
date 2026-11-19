class AddForeignKeysToRegistrationStepAnswers < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :registration_step_answers,
                    :registration_steps,
                    column: :registration_step_id,
                    on_delete: :cascade,
                    validate: false
    add_foreign_key :registration_step_answers,
                    :registration_steps,
                    column: :next_step_id,
                    on_delete: :nullify,
                    validate: false
  end
end
