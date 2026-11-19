module Registrations
  module SendInclusivePractice
    class LeadersRegistrationJourneyBuilder < BaseRegistrationJourneyBuilder
      attr_reader :registration_journey

      def initialize
        @registration_journey = ::RegistrationJourney.create!(
          name: Courses::SendInclusivePractice::Leaders::NAME,
          slug: Courses::SendInclusivePractice::Leaders::JOURNEY_SLUG,
          course: Course.find_by_identifier(Courses::SendInclusivePractice::Leaders::IDENTIFIER),
        )
      end
    end
  end
end
