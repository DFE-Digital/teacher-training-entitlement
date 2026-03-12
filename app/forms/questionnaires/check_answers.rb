module Questionnaires
  class CheckAnswers < Base
    include Helpers::Institution

    def previous_step
      :share_provider
    end

    def next_step; end

    def last_step?
      true
    end

    def after_save
      wizard.store["funding_amount"] = nil

      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true

      HandleSubmissionForStore.new(store: wizard.store).call
    end
  end
end
