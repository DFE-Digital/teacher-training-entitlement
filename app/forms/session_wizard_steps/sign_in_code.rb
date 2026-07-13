module SessionWizardSteps
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 8 }
    validate :validate_correct_code

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

    def validate_correct_code
      if user.blank?
        errors.add(:code, :incorrect)
      elsif user.otp_locked_out?
        errors.add(:code, :locked)
      elsif user.otp&.matches?(code)
        if user.otp.expired?
          errors.add(:code, :expired)
        end
      else
        user.increment_otp_failed_attempts!
        if user.otp_locked_out?
          errors.add(:code, :locked)
        else
          errors.add(:code, :incorrect)
        end
      end
    end
  end
end
