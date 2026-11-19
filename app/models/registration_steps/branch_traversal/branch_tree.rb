module RegistrationSteps
  module BranchTraversal
    #
    # Collects the steps belonging to a selected branch, stopping before
    # the point where that branch rejoins the rest of the journey.
    #
    #     [Choice] -- A --> [A1] --> [A2] --┐
    #               \-- B --> [B1] ---------┴--> [Join]
    #
    # If the choice changes from A, returns [A1, A2] so their answers can be cleared.
    # The join and the other branch are left out.
    #
    class BranchTree
      def initialize(registration_journey:, registration_step:, answers:)
        @registration_journey = registration_journey
        @registration_step = registration_step
        @answers = answers
      end

      def call
        next_step = registration_step.next_registration_step_for(answers:)
        return [] unless next_step

        branch_tree_for(
          root_step: next_step,
          stop_at_step: registration_step.branch_join_step,
        )
      end

    private

      attr_reader :registration_journey, :registration_step, :answers

      # Collects steps reachable through +previous_step_id+, stopping at a join or
      # a previously visited step so shared paths and cycles are not traversed twice.
      def branch_tree_for(root_step:, stop_at_step: nil, visited: Set.new)
        return [] if root_step == stop_at_step || visited.include?(root_step)

        visited = visited.dup.add(root_step)
        children = registration_journey.registration_steps
          .select { |step| step.previous_step_id == root_step.id && step != stop_at_step }
          .sort_by(&:id)
          .flat_map do |step|
            branch_tree_for(root_step: step, stop_at_step:, visited:)
          end

        [root_step, *children]
      end
    end
  end
end
