module Registrations
  module Steps
    module Spikes
      module CourseOne
        class Cheese
          include DfE::Wizard::Step

          TITLE = "What's your favourite cheese".freeze
          PARTIAL = "radio_buttons".freeze
          ATTRIBUTE = :favourite_cheese
          ANSWER_DISPLAY_NAME = "Favourite cheese".freeze

          attribute ATTRIBUTE, :string
          validates ATTRIBUTE, presence: true

          def self.permitted_params = [ATTRIBUTE]

          def self.answer_options
            [{ name: "Cheddar", value: "cheddar" }, { name: "Brie", value: "brie" }]
          end

          def display_answer_value(value:)
            self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
          end
        end
      end
    end
  end
end
