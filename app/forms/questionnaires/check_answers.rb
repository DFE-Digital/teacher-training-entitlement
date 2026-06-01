module Questionnaires
  class CheckAnswers < Base
    def previous_step
      :share_provider
    end

    def next_step
      :registration_submitted
    end

    def last_step?
      false
    end

    def after_save
      wizard.store["funding_amount"] = nil
      wizard.store["submitted"] = true

      HandleSubmissionForStore.new(store: wizard.store).call
    end
  end
end
