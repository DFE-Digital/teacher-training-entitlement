module Registration
  module Steps
    module StateFundedSchool
      class IneligibleForFunding
        include Base

        class UnexpectedEligibilityStatusCode < StandardError; end

        TEMPLATES = {
          ::FundingEligibilities::NOT_IN_ENGLAND => "not_in_england",
          ::FundingEligibilities::PREVIOUSLY_FUNDED => "previously_funded",
          ::FundingEligibilities::INELIGIBLE_SETTING => "ineligible_setting",
        }.freeze

        def self.permitted_params
          []
        end

        def status_code
          return ::FundingEligibilities::INELIGIBLE_SETTING if state_store.work_setting == Institution::OTHER

          state_store.funding_eligibility_result
        end

        def template
          TEMPLATES.fetch(status_code) do
            raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{status_code}"
          end
        end
      end
    end
  end
end
