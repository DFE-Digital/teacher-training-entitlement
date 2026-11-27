module Registrations
  module Steps
    module SendInclusivePractice
      class CheckAnswers < Shared::HtmlPartial
        with_title "Check answers"
        with_partial "registrations/send_inclusive_practice/check_answers"

        def redirect_target
          "/applications"
        end
      end
    end
  end
end
