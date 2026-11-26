module Registrations
  module Steps
    module ExcellenceInReception
      class WorkSetting
        include DfE::Wizard::Step

        TITLE = "Tell us where you work".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :work_setting
        TEXTS = [
          {
            "text" => [
              "Make sure the information you provide is correct, as your provider will check your details.",
              "Register using your current workplace details, even if they will change soon.",
            ],
            "text_class" => "govuk-hint",
          },
        ].freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Select the setting that you work in" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [
            { name: "State-funded nursery, pre-school, school or academy trust", value: Institution::STATE_FUNDED_INSTITUTION },
            { name: "Private nursery, pre-school or school", value: Institution::PRIVATE_INSTITUTION },
            { name: "Other", value: Institution::OTHER },
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
