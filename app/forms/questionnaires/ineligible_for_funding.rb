module Questionnaires
  class IneligibleForFunding < Base
    def next_step
      :funding_your_course
    end

    def previous_step
      if wizard.query_store.work_setting == Institution::STATE_FUNDED_INSTITUTION
        :choose_school
      else
        :work_setting
      end
    end

    def funding_eligiblity_status_code
      funding_eligibility.funding_eligiblity_status_code
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: inside_catchment?,
        user: wizard.query_store.current_user,
        work_setting: wizard.query_store.work_setting,
      )
    end

    delegate :course,
             :lead_provider,
             :inside_catchment?,
             to: :query_store
  end
end
