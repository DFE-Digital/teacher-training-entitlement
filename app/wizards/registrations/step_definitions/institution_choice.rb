module Registrations
  module StepDefinitions
    class InstitutionChoice < FormStep
      def display_answer_value(value:)
        institution = Institution.find_by(id: value) if value.to_s.match?(/\A\d+\z/)

        institution&.name || step_definition.display_answer_value(value:)
      end

      def type_as_param
        "choose_institution"
      end
    end
  end
end
