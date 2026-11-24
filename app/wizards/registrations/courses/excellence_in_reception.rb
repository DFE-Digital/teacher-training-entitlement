module Registrations
  module Courses
    class ExcellenceInReception
      NAME = "Excellence In Reception".freeze
      JOURNEY_SLUG = "excellence-in-reception".freeze
      IDENTIFIER = ::Course::TTE_EARLY_YEARS
      LEGACY_IDENTIFIER = "npd-excellence-in-reception-teaching".freeze

      FUNDING_ELIGIBILITY_CLASS = ::Registrations::ExcellenceInReception::FundingEligibility
      APPLICATION_COMPLETION_CLASS = ::Registrations::ExcellenceInReception::ApplicationCreation

      def self.course
        Course.reception
      end
    end
  end
end
