module Questionnaires
  class IneligibleForFunding < Base
    class UnexpectedEligibilityStatusCode < StandardError; end

    INELIGIBLE_SETTING = "ineligible_setting".freeze
    NOT_IN_ENGLAND = "not_in_england".freeze
    PREVIOUSLY_FUNDED = "previously_funded".freeze

    attr_accessor :version

    def next_step
      :funding_your_course
    end

    def previous_step
      # Check the catchment first as works_in_school? can also be true
      return :work_setting unless inside_catchment?
      return :choose_school if works_in_school?
      return :choose_school if kind_of_nursery_public?
      return :kind_of_nursery if kind_of_nursery_private?

      :work_setting # works_in_other
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when FundingEligibility::NOT_IN_ENGLAND
                                 NOT_IN_ENGLAND
                               when FundingEligibility::PREVIOUSLY_FUNDED
                                 PREVIOUSLY_FUNDED
                               when FundingEligibility::INELIGIBLE_SETTING
                                 INELIGIBLE_SETTING
                               else
                                 raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{funding_eligiblity_status_code}"
                               end
    end

    def funding_eligiblity_status_code
      return :ineligible_setting if kind_of_nursery_private? || works_in_other?

      @funding_eligiblity_status_code ||= funding_eligibility.funding_eligiblity_status_code
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: inside_catchment?,
        query_store: wizard.query_store,
      )
    end

    delegate :course,
             :lead_provider,
             :inside_catchment?,
             :works_in_other?,
             :works_in_school?,
             :kind_of_nursery_private?,
             :kind_of_nursery_public?,
             to: :query_store
  end
end
