module SessionWizardSteps
  class SignIn < Base
    attr_reader :email

    validates :email, presence: true, email: true

    def self.permitted_params
      [
        :email,
      ]
    end

    def email=(value)
      if value
        @email = value.strip.downcase
      end
    end

    def next_step
      :sign_in_code
    end

    def after_save
      admin = AdminUser.find_by(email:)
      return unless admin

      otp = OTP.generate
      admin.update!(otp_hash: otp.code, otp_expires_at: otp.expires_at, otp_failed_attempts: 0)
      GenericMailer.with(to: email, code: otp.code).confirmation_code.deliver_now
    rescue Notifications::Client::BadRequestError => e
      Rails.logger.error("Failed to send OTP email: #{e.message}")
    end
  end
end
