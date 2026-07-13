module SessionWizardSteps
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 8 }, user_otp_code: true
    validate :increment_failed_attempts_if_incorrect

    def self.permitted_params
      [
        :code,
      ]
    end

    def next_step
      nil
    end

    def admin
      @admin ||= AdminUser.find_by(email: wizard.store["email"])
    end
    alias_method :user, :admin

    def after_save
      admin.clear_otp!
    end

  private

    def increment_failed_attempts_if_incorrect
      return unless errors.of_kind?(:code, :incorrect)

      user&.increment_otp_failed_attempts!
      if user&.otp_locked_out?
        errors.delete(:code, :incorrect)
        errors.add(:code, :locked)
      end
    end
  end
end
