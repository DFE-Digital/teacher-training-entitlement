class AddMilestoneToDeclaration < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # the foreign_key will be added later once the course_cohort has its milestones setup
    add_reference :declarations, :milestone, null: true, index: { algorithm: :concurrently }
  end
end
