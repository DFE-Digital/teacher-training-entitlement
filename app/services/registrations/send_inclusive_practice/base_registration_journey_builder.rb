module Registrations
  module SendInclusivePractice
    class BaseRegistrationJourneyBuilder < ::Registrations::BaseRegistrationJourneyBuilder
      attr_reader :registration_journey

      def initialize(registration_journey:)
        @registration_journey = registration_journey
      end

      def call
        create_step!(
          name: "Check answers",
          slug: "check-answers",
          step_class: RegistrationSteps::CheckAnswers,
          redirect_path: "/applications",
          # previous_step_id: start.id,
        )
      end
    end
  end
end
