class AdminUser < ApplicationRecord
  MAX_OTP_ATTEMPTS = 5

  has_many :bulk_operations

  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  def name_with_email
    "#{full_name} (#{email})"
  end

  def otp_locked_out?
    otp_failed_attempts >= MAX_OTP_ATTEMPTS
  end

  def increment_otp_failed_attempts!
    with_lock do
      increment!(:otp_failed_attempts)
      clear_otp! if otp_locked_out?
    end
  end

  def clear_otp!
    update!(otp_hash: nil, otp_expires_at: nil)
  end
end
