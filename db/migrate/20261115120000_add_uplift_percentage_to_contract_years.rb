class AddUpliftPercentageToContractYears < ActiveRecord::Migration[8.1]
  def change
    add_column :contract_years, :uplift_percentage, :decimal, precision: 10, scale: 4
  end
end
