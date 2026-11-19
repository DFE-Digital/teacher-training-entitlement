module Registrations
  class BuildRegistrationJourneys
    JOURNEY_BUILDER_CLASSES = [
      ExcellenceInReception::RegistrationJourneyBuilder,
      SendInclusivePractice::TeachersRegistrationJourneyBuilder,
      SendInclusivePractice::LeadersRegistrationJourneyBuilder,
      CourseSelection::RegistrationJourneyBuilder,
    ].freeze

    def call
      RegistrationJourney.destroy_all

      JOURNEY_BUILDER_CLASSES.each do |builder_class|
        builder_class.new.call
      end
    end
  end
end
