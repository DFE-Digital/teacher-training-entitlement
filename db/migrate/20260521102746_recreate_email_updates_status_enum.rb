class RecreateEmailUpdatesStatusEnum < ActiveRecord::Migration[8.1]
  def up
    safety_assured { rename_column :users, :email_updates_status, :old_email_updates_status }

    safety_assured { execute "DROP TYPE IF EXISTS email_updates_statuses" }
    create_enum :email_updates_statuses, %w[npd_registration_open]

    add_column :users, :email_updates_status, :enum, enum_type: "email_updates_statuses", default: nil

    safety_assured do
      execute <<~SQL.squish
        UPDATE users
        SET email_updates_status = CASE old_email_updates_status
          WHEN 0 THEN NULL
          ELSE 'npd_registration_open'::email_updates_statuses
        END
      SQL
    end

    safety_assured { remove_column :users, :old_email_updates_status, :integer }
  end

  def down
    add_column :users, :old_email_updates_status, :integer, default: 0

    safety_assured do
      execute <<~SQL.squish
        UPDATE users
        SET old_email_updates_status = CASE email_updates_status
          WHEN 'npd_registration_open' THEN 1
          ELSE 0
        END
      SQL
    end

    safety_assured { remove_column :users, :email_updates_status, :enum, enum_type: "email_updates_statuses" }
    safety_assured { rename_column :users, :old_email_updates_status, :email_updates_status }
    drop_enum :email_updates_statuses
  end
end
