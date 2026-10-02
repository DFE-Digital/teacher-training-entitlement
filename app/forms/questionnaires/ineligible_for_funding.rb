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
      return :teacher_catchment unless wizard.query_store.inside_catchment?

      if wizard.query_store.work_setting == Institution::STATE_FUNDED_INSTITUTION
        :choose_school
      else
        :work_setting
      end
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when FundingEligibility::Constants::NOT_IN_ENGLAND
                                 NOT_IN_ENGLAND
                               when FundingEligibility::Constants::PREVIOUSLY_FUNDED
                                 PREVIOUSLY_FUNDED
                               when FundingEligibility::Constants::INELIGIBLE_SETTING
                                 INELIGIBLE_SETTING
                               else
                                 raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{funding_eligiblity_status_code}"
                               end
    end

    delegate :course,
             :lead_provider,
             :inside_catchment?,
             :works_in_other?,
             :works_in_school?,
             :kind_of_nursery_private?,
             :kind_of_nursery_public?,
             :funding_eligiblity_status_code,
             to: :query_store
  end
end
