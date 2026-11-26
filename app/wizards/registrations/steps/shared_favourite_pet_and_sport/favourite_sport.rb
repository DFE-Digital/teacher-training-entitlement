module Registrations
  module Steps
    module SharedFavouritePetAndSport
      class FavouriteSport
        include DfE::Wizard::Step

        TITLE = "What's your favourite sport?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :favourite_sport
        ANSWER_DISPLAY_NAME = "Favourite sport".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: true

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [
            { name: "Football", value: "football" },
            { name: "Cricket", value: "cricket" },
            { name: "Rugby", value: "rugby" },
            { name: "Tennis", value: "tennis" },
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
