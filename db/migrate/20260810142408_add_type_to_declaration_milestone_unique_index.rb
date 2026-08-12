# frozen_string_literal: true

class AddTypeToDeclarationMilestoneUniqueIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_index :declarations,
                 name: :index_declarations_on_application_id_and_milestone_id,
                 algorithm: :concurrently

    add_index :declarations,
              %i[application_id milestone_id type],
              unique: true,
              where: "(state = ANY (ARRAY['eligible'::declaration_states, 'payable'::declaration_states, 'paid'::declaration_states, 'submitted'::declaration_states]))",
              name: :index_declarations_on_application_id_and_milestone_id,
              algorithm: :concurrently
  end

  def down
    remove_index :declarations,
                 name: :index_declarations_on_application_id_and_milestone_id,
                 algorithm: :concurrently

    add_index :declarations,
              %i[application_id milestone_id],
              unique: true,
              where: "(state = ANY (ARRAY['eligible'::declaration_states, 'payable'::declaration_states, 'paid'::declaration_states, 'submitted'::declaration_states]))",
              name: :index_declarations_on_application_id_and_milestone_id,
              algorithm: :concurrently
  end
end
