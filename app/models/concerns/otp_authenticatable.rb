module OtpAuthenticatable
  extend ActiveSupport::Concern

  MAX_OTP_ATTEMPTS = 5

  def generate_otp!
    code = rand(100_000..999_999).to_s
    update!(otp_hash: code, otp_expires_at: 10.minutes.from_now, otp_failed_attempts: 0)
    code
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
