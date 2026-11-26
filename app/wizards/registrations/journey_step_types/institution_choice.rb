module Registrations
  module JourneyStepTypes
    class InstitutionChoice < RadioButtons
      TYPE_AS_PARAM = "choose_institution".freeze

      def display_answer_value(value:)
        institution = Institution.find_by(id: value) if value.to_s.match?(/\A\d+\z/)

        institution&.name || super
      end
    end
  end
end
