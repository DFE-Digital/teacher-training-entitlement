module Registrations
  module Steps
    module Spikes
      module CourseTwo
        class CheckAnswers
          include DfE::Wizard::Step

          TITLE = "Check your answers and submit".freeze
          PARTIAL = "check_answers".freeze

          def self.permitted_params = []

          def after_update
            wizard.course.application_creation_service_class_name.constantize.new(wizard_step: self).call
          end
        end
      end
    end
  end
end
