module Registrations
  module FundingEligibility
    class NpdService < BaseStepService
      def call
        funding_eligibility_result = nil
        funding_eligibility_result_text = nil
        if wizard.state_store["teacher_catchment"] != "England"
          funding_eligibility_result_text = "You're not eligible because you're not in England"
          funding_eligibility_result = "ineligible"
        else
          institution = Institution.find(wizard.state_store["institution_id"])
          if institution.eligible_establishment?

            funding_eligibility_result_text = "You're eligible for funding"
            funding_eligibility_result = "funded"
          else
            funding_eligibility_result_text = "You're school is not eligible for funding"
            funding_eligibility_result = "ineligible"
          end
        end

        wizard.state_store.write(funding_eligibility_result:)
        wizard.state_store.write(funding_eligibility_result_text:)
      end
    end
  end
end
