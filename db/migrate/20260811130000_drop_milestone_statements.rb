class DropMilestoneStatements < ActiveRecord::Migration[8.1]
  def change
    drop_table :milestone_statements do |t|
      t.datetime :created_at, null: false
      t.bigint :milestone_id, null: false
      t.bigint :statement_id, null: false
      t.datetime :updated_at, null: false
    end
  end
end
