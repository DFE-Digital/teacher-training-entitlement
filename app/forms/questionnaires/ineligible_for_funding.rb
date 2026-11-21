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
      return :teacher_catchment unless inside_catchment?

      if works_in_school?
        :choose_school
      else
        :work_setting
      end
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when FundingEligibilities::NOT_IN_ENGLAND
                                 NOT_IN_ENGLAND
                               when FundingEligibilities::PREVIOUSLY_FUNDED
                                 PREVIOUSLY_FUNDED
                               when FundingEligibilities::INELIGIBLE_SETTING
                                 INELIGIBLE_SETTING
                               else
                                 raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{funding_eligiblity_status_code}"
                               end
    end

    def funding_eligiblity_status_code
      return :ineligible_setting if works_in_other?

      @funding_eligiblity_status_code ||= FundingEligibilities.for_course(course).evaluate(wizard.query_store)
    end

    delegate :course,
             :lead_provider,
             :inside_catchment?,
             :works_in_other?,
             :works_in_school?,
             to: :query_store
  end
end
