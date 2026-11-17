class CreateTrsWebhookMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :trs_webhook_messages do |t|
      t.string :message_id, null: false
      t.string :message_type, null: false
      t.string :message_source
      t.datetime :sent_at, null: false
      t.jsonb :message, null: false
      t.string :status, null: false, default: "pending"
      t.text :status_comment
      t.datetime :processed_at

      t.timestamps
    end
    add_index :trs_webhook_messages, :message_id, unique: true
  end
end
