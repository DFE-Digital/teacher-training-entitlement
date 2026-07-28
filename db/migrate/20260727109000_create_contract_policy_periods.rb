class CreateContractPolicyPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_policy_periods do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :policy_period, null: false, foreign_key: true

      t.timestamps
    end

    add_index :contract_policy_periods, %i[contract_id policy_period_id], unique: true
  end
end
