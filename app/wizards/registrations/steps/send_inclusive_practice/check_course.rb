module Registrations
  module Steps
    module SendInclusivePractice
      class CheckCourse < Shared::Plain

        def self.permitted_params = []

        def title
          "You are checking funding eligbility for the #{wizard.course.name} NPD course"
        end

        def text_data
          [{ "text" => [change_course_link], "text_class" => "govuk-hint" }]
        end

      private

        def change_course_link
          "If you want to check for a different course you can <a href=\"/registrations/course-selection/courses\">change your course</a>"
        end
      end
    end
  end
end
