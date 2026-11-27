class AddEmailToApplications < ActiveRecord::Migration[8.1]
  def up
    add_column :applications, :email, :string

    safety_assured do
      execute <<~SQL.squish
        UPDATE applications
        SET email = users.email
        FROM users
        WHERE users.id = applications.user_id
      SQL
    end
  end

  def down
    remove_column :applications, :email
  end
end
