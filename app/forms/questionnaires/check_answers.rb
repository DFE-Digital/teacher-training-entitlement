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

      create_application!
    end

  private

    def create_application!
      query_store = wizard.query_store
      rule_set = FundingEligibilities.for_course(query_store.course)

      service = Applications::Create.new(
        user: query_store.current_user,
        course_cohort: query_store.course_cohort,
        lead_provider: query_store.lead_provider,
        institution: query_store.institution,
        registration_data: wizard.store.except("generated_confirmation_code", "current_user", "current_user_id"),
        **rule_set.submission_attributes(query_store),
      )

      raise ActiveRecord::RecordInvalid, service unless service.call
    end
  end
end
