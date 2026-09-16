class RenameMilestonePaymentAmountToPaymentPercentage < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      rename_column :milestones, :payment_amount, :payment_percentage
    end
  end
end
