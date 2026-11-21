module Registration
  module Steps
    # Shared behaviour of every registration step.
    module Base
      extend ActiveSupport::Concern

      included do
        include DfE::Wizard::Step

        # Whether the step can only be reached by a signed-in teacher.
        class_attribute :requires_user, instance_writer: false, default: true
      end

      def state_store
        wizard.state_store
      end
    end
  end
end
