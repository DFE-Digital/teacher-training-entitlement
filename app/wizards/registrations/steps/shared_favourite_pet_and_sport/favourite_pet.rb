module Registrations
  module Steps
    module SharedFavouritePetAndSport
      class FavouritePet
        include DfE::Wizard::Step

        TITLE = "What's your favourite pet?".freeze
        PARTIAL = "radio_buttons".freeze
        ATTRIBUTE = :favourite_pet
        ANSWER_DISPLAY_NAME = "Favourite pet".freeze

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: true

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [
            { name: "Dog", value: "dog" },
            { name: "Cat", value: "cat" },
            { name: "Rabbit", value: "rabbit" },
            { name: "Other", value: "other" },
          ]
        end

        def display_answer_value(value:)
          self.class.answer_options.find { |option| option[:value].to_s == value.to_s }&.fetch(:name) || value
        end
      end
    end
  end
end
