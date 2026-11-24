module Registrations
  module Journeys
    # Demonstrates the available registration step types and explicit graph
    # composition using the Wizard 3 approach.
    class DocumentationExampleWizard < BaseJourneyWizard
      SLUG = "documentation-example".freeze

      def initialize(session:, current_step: nil, current_step_params: {}, current_user: nil)
        journey_definition = JourneyDefinition.new(
          name: "Registration Journey Documentation Example",
          slug: SLUG,
        )

        super(
          journey_definition:,
          session:,
          current_step:,
          current_step_params:,
          current_user:,
        )
      end

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          start = add_node(
            graph,
            name: "Start",
            slug: "start",
            step_class: Registrations::StepDefinitions::Plain,
            texts: [
              { text: "This journey demonstrates the available registration step types.", text_class: "govuk-body" },
            ],
          )

          branch_choice = add_node(
            graph,
            name: "Choose a path",
            slug: "choose-a-path",
            state_store_key: "documentation_path",
            answer_display_name: "Path",
            branch_join_step_slug: "choose-workplace",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: start.slug,
            answers: [
              { name: "Continue to the checkbox example", value: "checkbox", next_step_slug: "choose-preferences" },
              { name: "Skip to the branch end", value: "skip", next_step_slug: "short-branch" },
            ],
          )

          checkboxes = add_node(
            graph,
            name: "Choose your preferences",
            slug: "choose-preferences",
            state_store_key: "documentation_preferences",
            answer_display_name: "Preferences",
            step_class: Registrations::StepDefinitions::Checkboxes,
            previous_step_slug: branch_choice.slug,
            answers: [
              { name: "Send me updates", value: "updates" },
              { name: "Remember my choices", value: "remember" },
            ],
          )

          short_branch = add_node(
            graph,
            name: "Branch without a question",
            slug: "short-branch",
            step_class: Registrations::StepDefinitions::Plain,
            previous_step_slug: branch_choice.slug,
            texts: [
              { text: "This is the shorter branch.", text_class: "govuk-body" },
            ],
          )

          workplace = add_node(
            graph,
            name: "Choose your workplace",
            slug: "choose-workplace",
            state_store_key: "institution_id",
            answer_display_name: "Workplace",
            step_class: Registrations::StepDefinitions::InstitutionChoice,
            previous_step_slug: checkboxes.slug,
          )

          information = add_node(
            graph,
            name: "More information",
            slug: "more-information",
            step_class: Registrations::StepDefinitions::HtmlPartial,
            html_partial: "registrations/documentation_example/more_information",
            previous_step_slug: workplace.slug,
          )

          course_start = add_node(
            graph,
            name: "Choose a course start date",
            slug: "course-start-date",
            state_store_key: "course_cohort_ecf_id",
            answer_display_name: "Course start date",
            step_class: Registrations::StepDefinitions::ViewComponent,
            view_component: "Registrations::CourseStartDateComponent",
            previous_step_slug: information.slug,
          )

          check_answers = add_node(
            graph,
            name: "Check your answers",
            slug: "check-answers",
            step_class: Registrations::StepDefinitions::CheckAnswers,
            previous_step_slug: course_start.slug,
            texts: [
              { text: "Review the information you have entered.", text_class: "govuk-body" },
            ],
          )

          graph.root start.graph_id
          graph.add_edge from: start.graph_id, to: branch_choice.graph_id
          graph.add_multiple_conditional_edges(
            from: branch_choice.graph_id,
            branches: [
              { when: -> { state_store[branch_choice.answer_key] == "checkbox" }, then: checkboxes.graph_id, label: "Continue to the checkbox example" },
              { when: -> { state_store[branch_choice.answer_key] == "skip" }, then: short_branch.graph_id, label: "Skip to the branch end" },
            ],
          )
          graph.add_edge from: checkboxes.graph_id, to: workplace.graph_id
          graph.add_edge from: short_branch.graph_id, to: workplace.graph_id
          graph.add_edge from: workplace.graph_id, to: information.graph_id
          graph.add_edge from: information.graph_id, to: course_start.graph_id
          graph.add_edge from: course_start.graph_id, to: check_answers.graph_id
        end
      end
    end
  end
end
