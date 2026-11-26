module Registrations
  module Steps
    module ExcellenceInReception
      class CannotRegisterYet
        include DfE::Wizard::Step

        TITLE = "You cannot register yet".freeze
        PARTIAL = "html_partial".freeze
        PARTIAL_NAME = "registrations/excellence_in_reception/email_updates_signup".freeze

        def self.permitted_params = []
      end
    end
  end
end
