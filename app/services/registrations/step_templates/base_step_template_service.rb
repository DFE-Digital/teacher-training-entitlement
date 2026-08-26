module Registrations
  module StepTemplates
    #
    # Base service class for generating step templates
    #
    class BaseStepTemplateService
      def initialize(registration_journey:, registration_template:)
        @registration_journey = registration_journey
        @registration_template = registration_template
      end

      def call
        raise "Must be implemented"
      end

    protected

      attr_reader :registration_journey, :registration_template
    end
  end
end
