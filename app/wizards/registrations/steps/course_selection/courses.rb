module Registrations
  module Steps
    module CourseSelection
      class Courses
        include DfE::Wizard::Step

        TITLE = "Which course would you like to apply for?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :course_journey_slug
        ANSWER_DISPLAY_NAME = "Course".freeze

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
