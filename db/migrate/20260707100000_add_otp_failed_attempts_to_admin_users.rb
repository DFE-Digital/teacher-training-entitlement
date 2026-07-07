class AddOtpFailedAttemptsToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :otp_failed_attempts, :integer, default: 0, null: false
  end
end
