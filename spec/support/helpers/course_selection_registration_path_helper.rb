module Helpers
  module CourseSelectionRegistrationPathHelper
    attr_reader :registration_journey

    def start_registration
      Registrations::BuildRegistrationJourneys.new.call

      @registration_journey = RegistrationJourney.find_by_slug("course-selection")

      navigate_to_page(path: "#{registration_journey_path}/courses", submit_form: false)
    end

    def registration_journey_path
      "/registrations/#{registration_journey.slug}"
    end

    def choose_excellence_in_reception_course
      expect_page_to_have(path: "#{registration_journey_path}/courses", submit_form: true) do
        page.choose("Excellence In Reception", visible: :all)
      end
    end

    def choose_send_leaders_course
      expect_page_to_have(path: "#{registration_journey_path}/courses", submit_form: true) do
        page.choose("Embedding inclusive practice for leaders", visible: :all)
      end
    end

    def choose_send_teachers_course
      expect_page_to_have(path: "#{registration_journey_path}/courses", submit_form: true) do
        page.choose("Embedding inclusive practice", visible: :all)
      end
    end
  end
end
