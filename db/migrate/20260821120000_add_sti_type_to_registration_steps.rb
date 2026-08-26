class AddStiTypeToRegistrationSteps < ActiveRecord::Migration[8.1]
  def change
    add_column :registration_steps, :sti_type, :string

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL.squish
            UPDATE registration_steps
            SET sti_type = CASE
              WHEN type IN ('Radio buttons', 'Dropdown select', 'Checkboxes') THEN 'RegistrationSteps::HtmlComponent'
              WHEN type = 'Custom step' THEN 'RegistrationSteps::CustomStep'
            END
          SQL
        end
      end
    end
  end
end
