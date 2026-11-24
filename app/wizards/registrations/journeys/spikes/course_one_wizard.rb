module Registrations
  module Journeys
    module Spikes
      class CourseOneWizard < BaseJourneyWizard
        def steps_processor
          @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            add_node(
              graph,
              name: "What's your favourite cheese", slug: "cheese",
              step_class: StepDefinitions::RadioButtons,
              answers: [
                { name: "Cheddar", value: "cheddar" },
                { name: "Brie", value: "brie" },
              ]
            )

            add_shared_journey(
              SharedFundingEligibilityJourneyWizard,
              graph:,
              after: :cheese,
              before: :check_answers,
              funding_eligibility_class: course_definition::FUNDING_ELIGIBILITY_CLASS,
            )

            add_node(
              graph,
              name: "Check your answers and submit",
              slug: "check-answers",
              step_class: Registrations::StepDefinitions::CheckAnswers,
              previous_step_slug: :cheese,
              services: [
                { class_name: course_definition::APPLICATION_COMPLETION_CLASS.name, execute_point: :after_update },
              ],
            )

            graph.root :cheese
          end
        end
      end
    end
  end
end
