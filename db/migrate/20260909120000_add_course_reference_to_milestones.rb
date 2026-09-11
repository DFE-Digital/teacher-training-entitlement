class AddCourseReferenceToMilestones < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :milestones, :course, null: true, index: { algorithm: :concurrently }
  end
end
