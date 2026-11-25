module Registrations
  module Journeys
    class SendInclusivePracticeWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          add_node(
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
          )

          add_node(
            graph,
            name: "You are are self-funding for the #{journey_definition.name} NPD course",
            slug: "self-funded-check-course",
            step_class: Registrations::StepDefinitions::Plain,
            texts: [
              {
                text: "If you want to check for a different course you can <a href=\"/registrations/#{Registrations::Journeys::CourseSelectionWizard::JOURNEY_SLUG}/#{Registrations::Journeys::CourseSelectionWizard::COURSES_STEP}\">change your course</a>",
                text_class: "govuk-hint",
              },
            ],
          )

          add_shared_journey(
            Spikes::SharedSendFundingEligibilityJourneyWizard,
            graph:,
            after: :check_course,
            before: :check_answers,
            connect_from_after: false,
          )

          add_node(
            graph,
            name: "Check answers",
            slug: "check-answers",
            step_class: Registrations::StepDefinitions::CheckAnswers,
            redirect_path: "/applications",
            previous_step_slug: :funding_eligibility_result,
          )

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
