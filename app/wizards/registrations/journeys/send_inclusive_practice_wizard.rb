module Registrations
  module Journeys
    class SendInclusivePracticeWizard < BaseJourneyWizard
      CHANGE_COURSE_LINK = "If you want to check for a different course you can <a href=\"/registrations/#{CourseSelectionWizard::JOURNEY_SLUG}/#{CourseSelectionWizard::COURSES_STEP}\">change your course</a>".freeze

      configure_step :check_course,
                     name: ->(wizard) { "You are checking funding eligbility for the #{wizard.journey_definition.name} NPD course" },
                     texts: [{ text: [CHANGE_COURSE_LINK], text_class: "govuk-hint" }]
      configure_step :self_funded_check_course,
                     name: ->(wizard) { "You are are self-funding for the #{wizard.journey_definition.name} NPD course" },
                     texts: [{ text: [CHANGE_COURSE_LINK], text_class: "govuk-hint" }]
      configure_step :check_answers,
                     name: "Check answers",
                     redirect_path: "/applications"

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :check_course,
                         JourneyStepTypes::Plain,
                         label: step_config(:check_course).fetch(:name)
          graph.add_node :self_funded_check_course,
                         JourneyStepTypes::Plain,
                         label: step_config(:self_funded_check_course).fetch(:name)

          add_shared_wizard(
            Spikes::SharedSendFundingEligibilityJourneyWizard.new(
              graph:,
              after: :check_course,
              before: :check_answers,
              add_node: method(:add_node),
              connect_from_after: false,
            ),
          )

          graph.add_node :check_answers,
                         JourneyStepTypes::CheckAnswers,
                         label: step_config(:check_answers).fetch(:name)

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
