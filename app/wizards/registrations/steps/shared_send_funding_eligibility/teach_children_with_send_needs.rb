module Registrations
  module Steps
    module SharedSendFundingEligibility
      class TeachChildrenWithSendNeeds
        include DfE::Wizard::Step

        TITLE = "Do you teach children with SEND needs?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :teaches_children_with_send_needs
        ANSWER_DISPLAY_NAME = "Teach children with SEND needs".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: true

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [{ name: "Yes", value: "yes" }, { name: "No", value: "no" }]
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
