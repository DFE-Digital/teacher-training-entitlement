module Registrations
  module Journeys
    class SharedSendInclusivePracticeWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          check_course = add_node(
            graph,
            name: "You are checking funding eligbility for the #{journey_definition.name} NPD course",
            slug: "check-course",
            step_class: Registrations::StepDefinitions::Plain,
            texts: [
              {
                text: "If you want to check for a different course you can <a href=\"/registrations/#{Registrations::Journeys::CourseSelectionWizard::JOURNEY_SLUG}/#{Registrations::Journeys::CourseSelectionWizard::COURSES_STEP}\">change your course</a>",
                text_class: "govuk-hint",
              },
            ],
            answers: [
              { name: "Self-funded", value: "true", state_store_key: "self_funded", next_step_slug: "check-answers" },
            ],
          )

          state_funded_school, _teaches_send, funding_result = add_shared_journey(
            Spikes::SharedSendFundingEligibilityJourneyWizard,
            graph:,
            after: check_course.graph_id,
            before: :check_answers,
            connect_from_after: false,
          )

          check_answers = add_node(
            graph,
            name: "Check answers",
            slug: "check-answers",
            step_class: Registrations::StepDefinitions::CheckAnswers,
            redirect_path: "/applications",
            previous_step_slug: funding_result.slug,
          )

          graph.root check_course.graph_id
          graph.add_multiple_conditional_edges(
            from: check_course.graph_id,
            branches: [
              {
                when: -> { state_store["self_funded"] == "true" },
                then: check_answers.graph_id,
                label: "Self-funded",
              },
            ],
            default: state_funded_school.graph_id,
          )
        end
      end
    end
  end
end
