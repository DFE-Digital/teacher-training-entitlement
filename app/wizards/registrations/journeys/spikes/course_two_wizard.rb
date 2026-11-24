module Registrations
  module Journeys
    module Spikes
      class CourseTwoWizard < BaseJourneyWizard
        def steps_processor
          @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            add_node(
              graph,
              name: "What's your favourite cracker", slug: "crackers",
              step_class: StepDefinitions::RadioButtons,
              answers: [
                { name: "Jacob's Cream cracker", value: "Jacob's Cream cracker" },
                { name: "Ryvita", value: "Ryvita" },
              ]
            )

            add_shared_journey(
              SharedFundingEligibilityJourneyWizard,
              graph:,
              after: :crackers,
              before: :colour,
              funding_eligibility_class: course_definition::FUNDING_ELIGIBILITY_CLASS,
            )

            add_node(
              graph,
              name: "What's your favourite colour", slug: "colour",
              step_class: StepDefinitions::RadioButtons,
              answers: [
                { name: "Blue", value: "blue" },
                { name: "Green", value: "green" },
                { name: "Red", value: "red" },
              ]
            )

            add_node(
              graph,
              name: "Check your answers and submit",
              slug: "check-answers",
              step_class: Registrations::StepDefinitions::CheckAnswers,
              previous_step_slug: :colour,
              services: [
                { class_name: course_definition::APPLICATION_COMPLETION_CLASS.name, execute_point: :after_update },
              ],
            )

            graph.root :crackers
            graph.add_edge from: :colour, to: :check_answers
          end
        end
      end
    end
  end
end
