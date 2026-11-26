module Registrations
  module JourneyStepTypes
    class CourseStartDate < RadioButtons
      TYPE_AS_PARAM = "course_start_date".freeze

      def answer_options
        course_cohorts = wizard.course.course_cohorts.registerable
                                   .includes(:cohort)
                                   .order(:training_starts_at).to_a

        options = course_cohorts[1..].map do |course_cohort|
          JourneyStep::Choice.new(
            name: course_cohort.cohort.name,
            value: course_cohort.ecf_id,
            display_value: course_cohort.cohort.name,
          )
        end
        options << JourneyStep::Choice.new(
          name: "I want to start at a later date",
          value: "later",
          display_value: "I want to start at a later date",
        )

        options
      end
    end
  end
end
