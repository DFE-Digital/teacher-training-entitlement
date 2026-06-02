module Questionnaires
  class RegistrationSubmitted < Base
    def previous_step; end

    def next_step; end

    def last_step?
      true
    end

    def requirements_met?
      true
    end

    def after_save
      wizard.session["clear_tra_login"] = true
    end
  end
end
