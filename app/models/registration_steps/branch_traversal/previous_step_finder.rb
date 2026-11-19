module RegistrationSteps
  module BranchTraversal
    #
    # Finds the step the user came from, using stored branch answers to resolve
    # the path back through a join:
    #
    #     [Choice] -> [A1] --┐
    #              -> [B1] --┴-> [Join]
    #
    # At [Join], returns the last step on the branch selected in +answers+.
    #
    class PreviousStepFinder
      def initialize(registration_journey:, registration_step:, answers:)
        @registration_journey = registration_journey
        @registration_step = registration_step
        @answers = answers.symbolize_keys
      end

      def call
        previous_steps = selected_answer_predecessors + registration_step.branch_decision_steps
          .filter_map { |branch_step| previous_step_from_branch(branch_step) }
        previous_steps.uniq!

        if previous_steps.many?
          raise ArgumentError, "Registration step #{registration_step.id} has multiple selected branch predecessors"
        end

        previous_steps.first || registration_step.previous_registration_step
      end

    private

      attr_reader :registration_journey, :registration_step, :answers

      # A step can be the destination of conditional answers from multiple
      # decision steps, even when it is not configured as a branch join.
      def selected_answer_predecessors
        registration_journey.registration_steps.filter_map do |candidate_step|
          answer_value = answers[candidate_step.answer_key.to_sym]
          next if answer_value.blank?

          candidate_step if candidate_step.next_registration_step_for(answers:) == registration_step
        end
      end

      # Uses the stored answer to find which branch led to +registration_step+,
      # then returns the step immediately before it:
      #
      #     state[branch_step.answer_key] = "A"
      #
      #     [Branch step] -- A --> [Branch root] -> [A1] -> [Registration step]
      #                    \-- B --> [Other branch] ...
      #                                               returns [A1]
      #
      # If the registration step is itself the branch root, the branch step is
      # returned as its predecessor.
      def previous_step_from_branch(branch_step)
        branch_root = branch_step.next_registration_step_for(answers:)

        return unless branch_root
        return branch_step if branch_root == registration_step

        last_step_before(from: branch_root)
      end

      # Walks the selected route from a branch root and returns the step immediately
      # before +target_step+. The visited set prevents malformed loops from hanging.
      def last_step_before(from:)
        visited_step_ids = Set.new
        current_step = from

        while current_step && !visited_step_ids.include?(current_step.id)
          visited_step_ids.add(current_step.id)

          next_step = next_step_for(current_step)
          return current_step if next_step == registration_step

          current_step = next_step
        end
      end

      # Chooses an answer-specific destination when present, otherwise the default
      # route for the step.
      def next_step_for(current_step)
        next_step_for_answer = current_step.next_registration_step_for(answers:)
        next_step_for_answer || default_next_step_for(current_step)
      end

      def default_next_step_for(step)
        DefaultNextStep.new(registration_journey:, registration_step: step).call
      end
    end
  end
end
