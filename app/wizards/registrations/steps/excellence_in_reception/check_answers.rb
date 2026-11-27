module Registrations
  module Steps
    module ExcellenceInReception
      class CheckAnswers < Shared::CheckAnswers
        with_title "Check your answers and submit"

        def self.permitted_params = []

        def after_update
          Registrations::ApplicationCreation.new(wizard_step: self).call
        end

        def redirect_target
          "/applications/#{wizard.state_store['application_ecf_id']}"
        end
      end
    end
  end
end
