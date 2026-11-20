module Registrations
  # Resolves which persisted journey step should be visited next or before.
  class Router
    attr_reader :router_step

    def initialize(params:, session:, current_user: nil)
      @router_step = Registrations::RouterStep.new(
        params:, session:,
        current_user:
      )
    end

    delegate :registration_journey, :registration_step, :state_store, to: :router_step

    def next_step_slug
      return unless registration_step

      next_registration_step&.slug&.to_sym
    end

    def previous_step_slug
      previous_registration_step&.slug&.to_sym
    end

    def previous_registration_step
      return unless registration_step

      RegistrationSteps::BranchTraversal::PreviousStepFinder.new(
        registration_journey:,
        registration_step:,
        answers: router_step.captured_values,
      ).call
    end

    def next_registration_step
      return unless registration_step

      RegistrationSteps::BranchTraversal::NextStepFinder.new(
        registration_journey:,
        registration_step:,
        answers: router_step.captured_values,
      ).call
    end

    def should_exit?
      next_step_slug == :exit || @router_step.slug == :exit
    end
  end
end
