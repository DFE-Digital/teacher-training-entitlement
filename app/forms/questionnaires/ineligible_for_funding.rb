module Questionnaires
  class IneligibleForFunding < Base
    class UnexpectedEligibilityStatusCode < StandardError; end

    include Helpers::Institution

    NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING = "not_eligible_for_scholarship_funding".freeze
    NOT_IN_ENGLAND = "not_in_england".freeze
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING = "already_funded/not_eligible_scholarship_funding".freeze

    attr_accessor :version

    def next_step
      :funding_your_course
    end

    def previous_step
      :teacher_catchment
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when FundingEligibility::NOT_IN_ENGLAND
                                 NOT_IN_ENGLAND
                               when FundingEligibility::PREVIOUSLY_FUNDED
                                 ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING
                               when FundingEligibility::INELIGIBLE_SETTING
                                 NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                               else
                                 raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{funding_eligiblity_status_code}"
                               end
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= funding_eligibility.funding_eligiblity_status_code
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: inside_catchment?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
        query_store: wizard.query_store,
      )
    end

    delegate :course,
             :lead_provider,
             :inside_catchment?,
             to: :query_store
  end
end
