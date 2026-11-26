module Registrations
  module Steps
    module ExcellenceInReception
      class ChooseSchool
        include DfE::Wizard::Step

        TITLE = "Select your workplace".freeze
        PARTIAL = "choose_institution".freeze
        ATTRIBUTE = :institution_id
        ANSWER_DISPLAY_NAME = "Workplace".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Enter a workplace name" }

        def self.permitted_params = [ATTRIBUTE]

        def display_answer_value(value:)
          institution = Institution.find_by(id: value) if value.to_s.match?(/\A\d+\z/)

          institution&.name || value
        end

        def after_update
          wizard.course.funding_eligibility_service_class.new(wizard_step: self).call
        end
      end
    end
  end
end
