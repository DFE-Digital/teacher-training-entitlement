module Registrations
  module Journeys
    # Course selection composed directly from DfE Wizard graph nodes.
    class CourseSelectionWizard < BaseJourneyWizard
      JOURNEY_SLUG = "course-selection".freeze
      COURSES_STEP = "courses".freeze

      def initialize(session:, current_step: nil, current_step_params: {}, current_user: nil)
        journey_definition = JourneyDefinition.new(name: "Course selection", slug: JOURNEY_SLUG)
        super(journey_definition:, session:, current_step:, current_step_params:, current_user:)
      end

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          start = add_node(
            graph,
            name: "Start",
            slug: "start",
            state_store_key: "self_funded",
            step_class: Registrations::StepDefinitions::HtmlPartial,
            html_partial: "registrations/course_selection/start",
          )

          courses = add_node(
            graph,
            name: "Which course would you like to apply for?",
            slug: COURSES_STEP,
            state_store_key: "course_journey_slug",
            step_class: Registrations::StepDefinitions::RadioButtons,
            redirect_path: "/registrations/:course_journey_slug",
            redirect_state_store_key: "course_journey_slug",
            previous_step_slug: start.slug,
            answers: course_selection_choices,
          )

          graph.root start.graph_id
          graph.add_edge from: start.graph_id, to: courses.graph_id
        end
      end

    private

      def course_selection_choices
        Course.displayable.where(identifier: Registrations::JourneyWizardFactory::COURSE_IDENTIFIERS).map do |course|
          { name: course.name, value: course.identifier }
        end
      end
    end
  end
end
