module Registrations
  class CourseStartDateComponent < BaseCustomViewComponent
    def answer_options
      course_cohorts = Course.includes(:course_cohorts)
                             .reception
                             .course_cohorts.registerable
                             .order(:training_starts_at).to_a

      options = course_cohorts[1..].map do |course_cohort|
        {
          value: course_cohort.ecf_id,
          display_value: course_cohort.cohort.name,
        }
      end
      options << { value: "later", display_value: "I want to start at a later date" }

      options
    end
  end
end
