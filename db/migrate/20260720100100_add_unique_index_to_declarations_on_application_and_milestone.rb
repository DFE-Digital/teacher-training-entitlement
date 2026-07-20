class AddUniqueIndexToDeclarationsOnApplicationAndMilestone < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :declarations,
              %i[application_id milestone_id],
              unique: true,
              where: "state IN ('eligible', 'payable', 'paid', 'submitted')",
              algorithm: :concurrently
  end
end
