class DropStatementItems < ActiveRecord::Migration[8.1]
  def change
    drop_table :statement_items do |t|
      t.datetime :created_at, null: false
      t.bigint :declaration_id
      t.uuid :ecf_id
      t.enum :state, default: "eligible", null: false, enum_type: "statement_item_states"
      t.bigint :statement_id, null: false
      t.datetime :updated_at, null: false
    end

    drop_enum :statement_item_states
  end
end
