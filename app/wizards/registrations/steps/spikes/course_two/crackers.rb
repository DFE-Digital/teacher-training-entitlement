module Registrations
  module Steps
    module Spikes
      module CourseTwo
        class Crackers
          include DfE::Wizard::Step

          TITLE = "What's your favourite cracker".freeze
          PARTIAL = "radio_buttons".freeze
          ATTRIBUTE = :crackers

          attribute ATTRIBUTE, :string
          validates ATTRIBUTE, presence: true

          def self.permitted_params = [ATTRIBUTE]

          def self.answer_options
            [
              { name: "Jacob's Cream cracker", value: "Jacob's Cream cracker" },
              { name: "Ryvita", value: "Ryvita" },
            ]
          end

          def display_answer_value(value:)
            self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
          end
        end
      end
    end
  end
end
