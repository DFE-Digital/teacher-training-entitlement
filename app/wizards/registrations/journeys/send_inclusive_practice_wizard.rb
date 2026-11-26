module Registrations
  module Journeys
    class SendInclusivePracticeWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :check_course, Steps::SendInclusivePractice::CheckCourse
          graph.add_node :self_funded_check_course, Steps::SendInclusivePractice::SelfFundedCheckCourse

          add_shared_wizard(
            Spikes::SharedSendFundingEligibilityJourneyWizard.new(
              graph:,
              after: :check_course,
              before: :check_answers,
            ),
          )

          graph.add_node :check_answers, Steps::SendInclusivePractice::CheckAnswers

          graph.conditional_root(potential_root: %i[check_course self_funded_check_course]) do |state|
            state["self_funded"] == "true" ? :self_funded_check_course : :check_course
          end

          graph.add_edge from: :check_course, to: :state_funded_school
          graph.add_edge from: :self_funded_check_course, to: :check_answers
        end
      end
    end
  end
end
