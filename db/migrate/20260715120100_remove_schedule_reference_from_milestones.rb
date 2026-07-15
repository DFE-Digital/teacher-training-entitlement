class RemoveScheduleReferenceFromMilestones < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    remove_foreign_key :milestones, :schedules if foreign_key_exists?(:milestones, :schedules)

    if index_exists?(:milestones, %i[schedule_id declaration_type], name: "index_milestones_on_schedule_id_and_declaration_type")
      remove_index :milestones, name: "index_milestones_on_schedule_id_and_declaration_type", algorithm: :concurrently
    end

    remove_index :milestones, :schedule_id, algorithm: :concurrently if index_exists?(:milestones, :schedule_id)
    safety_assured { remove_column :milestones, :schedule_id if column_exists?(:milestones, :schedule_id) }
  end

  def down
    add_reference :milestones, :schedule, null: true, foreign_key: false, index: { algorithm: :concurrently }
    add_index :milestones, %i[schedule_id declaration_type],
              unique: true,
              name: "index_milestones_on_schedule_id_and_declaration_type",
              algorithm: :concurrently
    add_foreign_key :milestones, :schedules, validate: false
  end
end
