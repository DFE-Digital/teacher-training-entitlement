module Registrations
  module Steps
    module ExcellenceInReception
      class ChooseYourProvider
        include DfE::Wizard::Step

        TITLE = "Select your training provider".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :lead_provider_id
        ANSWER_DISPLAY_NAME = "Provider".freeze

        attribute ATTRIBUTE, :integer
        validates ATTRIBUTE, presence: { message: "Choose a provider" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          LeadProvider.alphabetical.map { |provider| { name: provider.name, value: provider.id.to_s } }
        end

        def display_answer_value(value:)
          self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
        end
      end
    end
  end
end
