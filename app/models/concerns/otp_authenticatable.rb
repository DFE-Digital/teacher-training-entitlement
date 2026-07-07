module OtpAuthenticatable
  extend ActiveSupport::Concern

  def generate_otp!
    code = OtpCodeGenerator.new.call
    update!(otp_hash: code, otp_expires_at: 10.minutes.from_now)
    code
  end
end
