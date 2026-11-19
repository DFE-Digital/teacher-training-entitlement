module RegistrationSteps
  module BranchTraversal
    #
    # Finds the next step from the selected answer, falling back to the
    # journey's default route when the answer has no explicit destination.
    #
    # If the the next step is configured on the answer:
    #     explicit answer route: [Current] -- answer --> [Next step]
    #
    # If the the next step is not configured on the answer:
    #     default route:         [Current] -------------> [Default step]
    #
    class NextStepFinder
      def initialize(registration_journey:, registration_step:, answers:)
        @registration_journey = registration_journey
        @registration_step = registration_step
        @answers = answers.symbolize_keys
      end

      def call
        step = registration_step.next_registration_step_for(answers:)

        step || DefaultNextStep.new(registration_journey:, registration_step:).call
      end

    private

      def answer_value
        answers[registration_step.answer_key.to_sym]
      end

      attr_reader :registration_journey, :registration_step, :answers
    end
  end
end
