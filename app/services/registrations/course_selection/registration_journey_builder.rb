module Registrations
  module CourseSelection
    class RegistrationJourneyBuilder < BaseRegistrationJourneyBuilder
      attr_reader :registration_journey

      def initialize
        @registration_journey = ::RegistrationJourney.create!(
          name: Courses::CourseSelection::NAME,
          slug: Courses::CourseSelection::JOURNEY_SLUG,
        )
      end

      def call
        start = create_step!(
          name: "Start",
          state_store_key: "self_funded",
          step_class: RegistrationSteps::HtmlPartial,
          html_partial: "registrations/course_selection/start",
        )

        create_step!(
          name: "Which course would you like to apply for?",
          slug: "courses",
          state_store_key: "journey_slug",
          step_class: RegistrationSteps::RadioButtons,
          redirect_path: "/registrations/:journey_slug",
          redirect_state_store_key: "journey_slug",
          answers: course_selection_choices,
          previous_step_id: start.id,
        )
      end

    private

      def course_selection_choices
        journeys = ::RegistrationJourney.joins(:course).where.not(course_id: nil).merge(Course.displayable)
        journeys.map do |journey|
          {
            name: journey.name,
            value: journey.slug,
          }
        end
      end
    end
  end
end
