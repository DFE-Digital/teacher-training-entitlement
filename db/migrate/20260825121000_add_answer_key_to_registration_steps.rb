class AddAnswerKeyToRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_steps, :answer_key, :string
  end
end
