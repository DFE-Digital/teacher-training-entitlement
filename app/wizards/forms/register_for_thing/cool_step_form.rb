module Forms
  module RegisterForThing
    class CoolStepForm < CustomRegistrationStepForm
      include DfE::Wizard::Step

      def view_component(form:, registration_step:) # rubocop:disable Lint/UnusedMethodArgument
        Registrations::RegisterForThing::CoolComponent.new(step: self, form:)
      end

      def form_param_names
        %i[something something_else]
      end
    end
  end
end
