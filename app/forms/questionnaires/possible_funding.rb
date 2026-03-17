module Questionnaires
  class PossibleFunding < Base
    def next_step
      :share_provider
    end

    def previous_step
      return :kind_of_nursery if kind_of_nursery_private?

      :choose_school
    end

    def funding_amount
      @funding_amount ||= 200
    end

    def after_save
      wizard.store["funding_amount"] = funding_amount
      wizard.store.delete("funding")
    end

    def message_template
      "eligible_for_scholarship_funding"
    end

    delegate_missing_to :query_store
  end
end
