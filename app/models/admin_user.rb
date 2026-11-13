class AdminUser < ApplicationRecord
  has_many :bulk_operations

  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  before_save :email_downcase, if: -> { email_changed? }

  def otp
    return unless OTP.valid_code_format?(otp_hash) && otp_expires_at.present?

    OTP.new(code: otp_hash, expires_at: otp_expires_at)
  end

  def clear_otp!
    update!(otp_hash: nil, otp_expires_at: nil)
  end

  def name_with_email
    "#{full_name} (#{email})"
  end

private

  def email_downcase
    email&.downcase!
  end
end
