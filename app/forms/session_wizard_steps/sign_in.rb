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

      code = admin.generate_otp!
      GenericMailer.with(to: email, code:).confirmation_code.deliver_now
    rescue Notifications::Client::BadRequestError => e
      Rails.logger.error("Failed to send OTP email: #{e.message}")
    end
  end
end
