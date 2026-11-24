module Registrations
  module Courses
    class CourseOne
      NAME = "Course One".freeze
      IDENTIFIER = "course-one".freeze
      JOURNEY_SLUG = IDENTIFIER
      FUNDING_ELIGIBILITY_CLASS = ::Registrations::ExcellenceInReception::FundingEligibility
      APPLICATION_COMPLETION_CLASS = ::Registrations::ExcellenceInReception::ApplicationCreation

      def self.course
        Course.find_by(identifier: IDENTIFIER) || Course.create!(
          name: NAME,
          identifier: IDENTIFIER,
          short_code: "COURSE1",
          display: true,
        )
      end
    end
  end
end
