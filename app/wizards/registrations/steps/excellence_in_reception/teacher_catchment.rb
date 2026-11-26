module Registrations
  module Steps
    module ExcellenceInReception
      class TeacherCatchment
        include DfE::Wizard::Step

        TITLE = "Do you work in England?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :teacher_catchment
        ANSWER_DISPLAY_NAME = "Works in England?".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Select 'Yes' if you work in England" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [
            { name: "Yes", value: Institution::ENGLAND_SUBDIVISION_CODE },
            { name: "No", value: Institution::OTHER },
          ]
        end

        def display_answer_value(value:)
          self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
        end

        def after_update
          wizard.course.funding_eligibility_service_class.new(wizard_step: self).call
        end
      end
    end
  end
end
