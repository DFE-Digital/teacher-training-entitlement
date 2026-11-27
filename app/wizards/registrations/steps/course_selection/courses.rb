module Registrations
  module Steps
    module CourseSelection
      class Courses < Shared::RadioButtons
        with_title "Which course would you like to apply for?"
        with_attribute :course_journey_slug
        with_answer_display_name "Course"

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Select a course" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          Course.displayable.map { |course| { name: course.name, value: course.identifier } }
        end

        def redirect_target
          "/registrations/#{course_journey_slug}"
        end
      end
    end
  end
end
