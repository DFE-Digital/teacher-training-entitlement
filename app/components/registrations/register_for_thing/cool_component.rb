module Registrations
  module RegisterForThing
    class CoolComponent < BaseComponent
      def initialize(step:, form:)
        @step = step
        @form = form
        @wizard = step.wizard
      end
    end
  end
end
