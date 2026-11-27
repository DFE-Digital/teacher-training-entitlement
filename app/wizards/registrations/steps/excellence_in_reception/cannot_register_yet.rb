module Registrations
  module Steps
    module ExcellenceInReception
      class CannotRegisterYet < Shared::HtmlPartial
        with_title "You cannot register yet"
        with_partial "registrations/excellence_in_reception/email_updates_signup"

      end
    end
  end
end
