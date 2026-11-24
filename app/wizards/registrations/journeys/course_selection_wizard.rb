module Registrations
  module Journeys
    # Course selection composed directly from DfE Wizard graph nodes.
    class CourseSelectionWizard < BaseJourneyWizard
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
            slug: Registrations::Courses::CourseSelection::COURSES_STEP,
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
        Registrations::JourneyWizardFactory::COURSES.filter_map do |definition|
          course = Course.displayable.find_by(identifier: definition::IDENTIFIER)
          next unless course

          { name: course.name, value: definition::JOURNEY_SLUG }
        end
      end
    end
  end
end
