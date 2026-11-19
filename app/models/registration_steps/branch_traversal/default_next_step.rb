module RegistrationSteps
  module BranchTraversal
    #
    # Finds the default next step, excluding destinations used by conditional
    # answers. If the step is at the end of a branch, it returns that branch's
    # join instead:
    #
    #     [Branch step] -> [Join]
    #
    #     [Choice] -- answer A --> [A1] --┐
    #              -- answer B --> [B1] --┴-> [Join]
    #
    class DefaultNextStep
      def initialize(registration_journey:, registration_step:)
        @registration_journey = registration_journey
        @registration_step = registration_step
      end

      def call
        conditional_next_steps = registration_step.registration_step_answers.filter_map(&:next_step)

        # Conditional destinations also have previous_step_id for branch traversal, but are not the default route.
        explicit_next_steps = registration_journey.registration_steps.select do |step|
          step.previous_step == registration_step && !conditional_next_steps.include?(step)
        end
        if explicit_next_steps.many?
          raise ArgumentError, "Registration step #{registration_step.id} has multiple default next steps"
        end
        return explicit_next_steps.first if explicit_next_steps.any?

        find_innermost_branch&.branch_join_step
      end

    private

      # Finds the nearest enclosing branch whose join has not already been crossed.
      # This lets nested branches finish at their own join before the outer branch:
      #
      #     [Outer choice] -> [Inner choice] -> [Inner paths] -> [Inner join]
      #           └────────────────────────────────────────────> [Outer join]
      def find_innermost_branch
        crossed_join_ids = Set.new
        crossed_join_ids.add(registration_step.id) if registration_step.branch_decision_steps.exists?

        branch_step = registration_step.previous_step

        while branch_step
          branch_join_step = branch_step.branch_join_step
          return branch_step if branch_join_step && !crossed_join_ids.include?(branch_join_step.id)

          crossed_join_ids.add(branch_step.id) if branch_step.branch_decision_steps.exists?
          branch_step = branch_step.previous_step
        end
      end

      attr_reader :registration_journey, :registration_step
    end
  end
end
