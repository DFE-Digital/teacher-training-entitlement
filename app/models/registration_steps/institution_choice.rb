module RegistrationSteps
  class InstitutionChoice < RegistrationStep
    def display_answer_value(value:)
      institution = Institution.find_by(id: value) if value.to_s.match?(/\A\d+\z/)

      institution&.name || super
    end

    def type_as_param
      "choose_institution"
    end
  end
end
