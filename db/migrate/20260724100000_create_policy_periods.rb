class CreatePolicyPeriods < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    create_table :policy_periods do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_reference :course_cohorts, :policy_period, index: { algorithm: :concurrently }
  end
end
