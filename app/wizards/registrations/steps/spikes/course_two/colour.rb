module Registrations
  module Steps
    module Spikes
      module CourseTwo
        class Colour
          include DfE::Wizard::Step

          TITLE = "What's your favourite colour".freeze
          PARTIAL = "radio_buttons".freeze
          ATTRIBUTE = :colour

          attribute ATTRIBUTE, :string
          validates ATTRIBUTE, presence: true

          def self.permitted_params = [ATTRIBUTE]

          def self.answer_options
            [{ name: "Blue", value: "blue" }, { name: "Green", value: "green" }, { name: "Red", value: "red" }]
          end

          def display_answer_value(value:)
            self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
          end
        end
      end
    end
  end
end
