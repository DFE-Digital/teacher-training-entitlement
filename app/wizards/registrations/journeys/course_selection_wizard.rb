module Registrations
  module Journeys
    class CourseSelectionWizard < BaseJourneyWizard
      JOURNEY_SLUG = "course-selection".freeze
      COURSES_STEP = "courses".freeze

      configure_step :start,
                     name: "Start",
                     answer_key: :self_funded,
                     partial_name: "registrations/course_selection/start"
      configure_step :courses,
                     name: "Which course would you like to apply for?",
                     answer_key: :course_journey_slug,
                     answer_display_name: "Course",
                     requires_answer: true,
                     required_answer_message: "Select a course",
                     redirect_path: "/registrations/:course_journey_slug",
                     answers: lambda { |_wizard|
                       Course.displayable.map do |course|
                         Registrations::JourneyStep::Choice.new(name: course.name, value: course.identifier)
                       end
                     }

      def initialize(session:, current_step: nil, current_step_params: {}, current_user: nil)
        journey_definition = JourneyDefinition.new(name: "Course selection", slug: JOURNEY_SLUG)
        super(journey_definition:, session:, current_step:, current_step_params:, current_user:)
      end

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :start,
                         Registrations::JourneyStepTypes::HtmlPartial,
                         label: step_config(:start).fetch(:name)
          graph.add_node :courses,
                         Registrations::JourneyStepTypes::RadioButtons,
                         label: step_config(:courses).fetch(:name)
          graph.root :start
          graph.add_edge from: :start, to: :courses
        end
      end
    end
  end
end
