class AddStatementDateToMilestones < ActiveRecord::Migration[7.1]
  def change
    add_column :milestones, :statement_date, :date
  end
end
