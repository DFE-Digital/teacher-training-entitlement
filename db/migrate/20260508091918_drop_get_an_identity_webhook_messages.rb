class DropGetAnIdentityWebhookMessages < ActiveRecord::Migration[7.1]
  def up
    drop_table :get_an_identity_webhook_messages
  end

  def down
    create_table :get_an_identity_webhook_messages do |t|
      t.datetime :created_at, null: false
      t.jsonb :message
      t.string :message_id
      t.datetime :processed_at
      t.string :status, default: "pending"
      t.datetime :updated_at, null: false

      t.index :message_id, unique: true
      t.index :status
    end
  end
end
