module Registrations
  module Journeys
    class CourseSelectionWizard < BaseJourneyWizard
      JOURNEY_SLUG = "course-selection".freeze
      COURSES_STEP = "courses".freeze

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :start, Steps::CourseSelection::Start
          graph.add_node :courses, Steps::CourseSelection::Courses
          graph.root :start
          graph.add_edge from: :start, to: :courses
        end
      end

      def journey_slug
        JOURNEY_SLUG
      end
    end
  end
end
