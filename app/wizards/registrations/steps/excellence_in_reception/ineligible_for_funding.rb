module Registrations
  module Steps
    module ExcellenceInReception
      class IneligibleForFunding < Shared::HtmlPartial
        with_title "Funding eligibility result"
        with_partial "registrations/shared/funding_eligibility_result"
        with_display_on_check_answers false
      end
    end
  end
end
