module Registrations
  module Steps
    module ExcellenceInReception
      class ChooseYourProvider < Shared::RadioButtons
        with_title "Select your training provider"
        with_attribute :lead_provider_id
        with_answer_display_name "Provider"

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
