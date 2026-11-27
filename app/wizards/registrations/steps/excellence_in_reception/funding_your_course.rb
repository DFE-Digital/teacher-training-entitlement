module Registrations
  module Steps
    module ExcellenceInReception
      class FundingYourCourse < Shared::RadioButtons
        with_title "How are you funding your course?"
        with_attribute :funding
        with_answer_display_name "Course funding"

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Select an option" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [
            { name: "My workplace is covering the cost", value: "school" },
            { name: "My trust is paying", value: "trust" },
            { name: "I am paying", value: "self" },
            { name: "My course is being paid for in another way", value: "another", hint: "For example, I am sharing the costs with my workplace" },
          ]
        end

        def display_answer_value(value:)
          self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
        end
      end
    end
  end
end
