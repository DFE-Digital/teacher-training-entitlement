module Registrations
  module Steps
    module ExcellenceInReception
      class CheckAnswers
        include DfE::Wizard::Step

        TITLE = "Check your answers and submit".freeze
        PARTIAL = "check_answers".freeze

        def self.permitted_params = []

        def after_update
          wizard.course.application_creation_service_class_name.constantize.new(wizard_step: self).call
        end

        def redirect_target
          "/applications/#{wizard.state_store['application_ecf_id']}"
        end
      end
    end
  end
end
