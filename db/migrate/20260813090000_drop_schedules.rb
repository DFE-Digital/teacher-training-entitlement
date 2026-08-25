class DropSchedules < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    remove_index :course_cohorts, :schedule_id, algorithm: :concurrently if index_exists?(:course_cohorts, :schedule_id)
    safety_assured { remove_column :course_cohorts, :schedule_id if column_exists?(:course_cohorts, :schedule_id) }

    safety_assured { drop_table :schedules if table_exists?(:schedules) }
  end

  def down
    create_table :schedules do |t|
      t.date :acceptance_window_end
      t.date :acceptance_window_start
      t.enum :allowed_declaration_types, default: %w[started retained-1 retained-2 completed], array: true, enum_type: "declaration_types"
      t.references :cohort, null: false, foreign_key: true
      t.enum :course_group, enum_type: "course_group"
      t.uuid :ecf_id
      t.string :identifier, null: false
      t.string :name, null: false
      t.integer :policy_descriptor
      t.date :training_ends_at
      t.date :training_starts_at
      t.timestamps
    end

    add_index :schedules, :ecf_id, unique: true
    add_index :schedules, %i[identifier cohort_id], unique: true

    add_reference :course_cohorts, :schedule, index: { algorithm: :concurrently }
  end
end
