class AddCourseMilestoneOffsetsAndCourseCohortTrainingStart < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :milestones, :course, null: true, index: { algorithm: :concurrently }
    add_column :milestones, :acceptance_window_start_offset, :integer
    add_column :milestones, :acceptance_window_end_offset, :integer
    add_column :course_cohorts, :training_starts_at, :date
  end
end
