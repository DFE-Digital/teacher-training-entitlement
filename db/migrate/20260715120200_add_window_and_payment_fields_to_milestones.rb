class AddWindowAndPaymentFieldsToMilestones < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :milestones, :course_cohorts

    add_column :milestones, :acceptance_window_start_date, :date
    add_column :milestones, :acceptance_window_end_date, :date
    add_column :milestones, :payment_amount, :decimal, precision: 10, scale: 2
  end
end
