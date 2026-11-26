module Registrations
  module Steps
    module SendInclusivePractice
      class CheckAnswers
        include DfE::Wizard::Step

        TITLE = "Check answers".freeze
        PARTIAL = "check_answers".freeze

        def self.permitted_params = []

        def redirect_target
          "/applications"
        end
      end
    end
  end
end
