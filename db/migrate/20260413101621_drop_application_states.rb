class DropApplicationStates < ActiveRecord::Migration[8.1]
  def up
    drop_table :application_states
  end

  def down
    create_table :application_states do |t|
      t.references :application, null: false, foreign_key: true, index: true
      t.references :lead_provider, foreign_key: true, index: true
      t.uuid :ecf_id
      t.text :reason
      t.enum :status, enum_type: :application_statuses
      t.timestamps
    end

    add_index :application_states, :ecf_id, unique: true
    add_index :application_states, :status
  end
end
