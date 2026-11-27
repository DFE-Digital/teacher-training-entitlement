module Helpers
  module CourseSelectionRegistrationPathHelper
    def start_registration
      navigate_to_page(path: "#{registration_journey_path}/courses", submit_form: false)
    end

    def registration_journey_path
      "/registrations/course-selection"
    end

    def choose_excellence_in_reception_course
      choose_course(Course::TTE_EARLY_YEARS)
    end

    def choose_send_leaders_course
      choose_course(Course::SEND_INCLUSIVE_LEADERS)
    end

    def choose_send_teachers_course
      choose_course(Course::SEND_INCLUSIVE_TEACHERS)
    end

  private

    def choose_course(course_identifier)
      expect_page_to_have(path: "#{registration_journey_path}/courses", submit_form: true) do
        find("input[type='radio'][value='#{course_identifier}']", visible: :all).set(true)
      end
    end
  end
end
