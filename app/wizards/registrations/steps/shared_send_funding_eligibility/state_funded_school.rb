module Registrations
  module Steps
    module SharedSendFundingEligibility
      class StateFundedSchool
        include DfE::Wizard::Step

        TITLE = "Do you work in a state-funded school?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :state_funded_school
        ANSWER_DISPLAY_NAME = "Work in a state-funded school".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: true

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [{ name: "Yes", value: "yes" }, { name: "No", value: "no" }]
        end

        def display_answer_value(value:)
          self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
        end
      end
    end
  end
end
