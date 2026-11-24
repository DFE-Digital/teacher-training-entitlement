module Registrations
  module Courses
    class CourseTwo
      NAME = "Course Two".freeze
      IDENTIFIER = "course-two".freeze
      JOURNEY_SLUG = IDENTIFIER
      FUNDING_ELIGIBILITY_CLASS = ::Registrations::ExcellenceInReception::FundingEligibility
      APPLICATION_COMPLETION_CLASS = ::Registrations::ExcellenceInReception::ApplicationCreation

      def self.course
        Course.find_by(identifier: IDENTIFIER) || Course.create!(
          name: NAME,
          identifier: IDENTIFIER,
          short_code: "COURSE2",
          display: true,
        )
      end
    end
  end
end
