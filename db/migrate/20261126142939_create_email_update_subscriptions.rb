class CreateEmailUpdateSubscriptions < ActiveRecord::Migration[8.1]
  def up
    create_table :email_update_subscriptions do |t|
      t.string :email, null: false
      t.text :full_name
      t.enum :status, enum_type: "email_updates_statuses", null: false
      t.string :unsubscribe_key, null: false

      t.timestamps
    end
    add_index :email_update_subscriptions, :unsubscribe_key, unique: true
    add_index :email_update_subscriptions, %i[email status], unique: true

    safety_assured do
      execute <<~SQL.squish
        INSERT INTO email_update_subscriptions (email, full_name, status, unsubscribe_key, created_at, updated_at)
        SELECT email, full_name, email_updates_status, COALESCE(email_updates_unsubscribe_key, gen_random_uuid()::text), created_at, updated_at
        FROM users
        WHERE email_updates_status IS NOT NULL AND archived_at IS NULL
      SQL
    end
  end

  def down
    drop_table :email_update_subscriptions
  end
end
