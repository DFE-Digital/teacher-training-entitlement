module Registrations
  module SendInclusivePractice
    class TeachersRegistrationJourneyBuilder < BaseRegistrationJourneyBuilder
      def initialize
        @registration_journey = ::RegistrationJourney.create!(
          name: Courses::SendInclusivePractice::Teachers::NAME,
          slug: Courses::SendInclusivePractice::Teachers::JOURNEY_SLUG,
          course: Course.find_by_identifier(Courses::SendInclusivePractice::Teachers::IDENTIFIER),
        )
      end
    end
  end
end
