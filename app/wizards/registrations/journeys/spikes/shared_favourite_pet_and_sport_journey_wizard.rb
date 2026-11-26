module Registrations
  module Journeys
    module Spikes
      class SharedFavouritePetAndSportJourneyWizard
        extend Registrations::StepConfiguration

        attr_reader :graph, :after, :before

        configure_step :favourite_pet,
                       name: "What's your favourite pet?",
                       answer_key: :favourite_pet,
                       answer_display_name: "Favourite pet",
                       requires_answer: true,
                       answers: [
                         Registrations::JourneyStep::Choice.new(name: "Dog", value: "dog"),
                         Registrations::JourneyStep::Choice.new(name: "Cat", value: "cat"),
                         Registrations::JourneyStep::Choice.new(name: "Rabbit", value: "rabbit"),
                         Registrations::JourneyStep::Choice.new(name: "Other", value: "other"),
                       ].freeze
        configure_step :favourite_sport,
                       name: "What's your favourite sport?",
                       answer_key: :favourite_sport,
                       answer_display_name: "Favourite sport",
                       requires_answer: true,
                       services: [
                         {
                           class_name: ->(wizard) { wizard.course.funding_eligibility_service_class },
                           execute_point: :after_update,
                         },
                       ],
                       answers: [
                         Registrations::JourneyStep::Choice.new(name: "Football", value: "football"),
                         Registrations::JourneyStep::Choice.new(name: "Cricket", value: "cricket"),
                         Registrations::JourneyStep::Choice.new(name: "Rugby", value: "rugby"),
                         Registrations::JourneyStep::Choice.new(name: "Tennis", value: "tennis"),
                       ].freeze
        configure_step :funding_eligibility_result,
                       name: "Funding eligibility result",
                       partial_name: "registrations/shared/funding_eligibility_result"

        def initialize(graph:, after:, before:)
          @graph = graph
          @after = after
          @before = before
        end

        def step_configurations
          self.class.step_configurations
        end

        def add_to_graph
          graph.add_node :favourite_pet,
                         Registrations::JourneyStepTypes::RadioButtons,
                         label: step_configurations.dig(:favourite_pet, :name)
          graph.add_node :favourite_sport,
                         Registrations::JourneyStepTypes::RadioButtons,
                         label: step_configurations.dig(:favourite_sport, :name)
          graph.add_node :funding_eligibility_result,
                         Registrations::JourneyStepTypes::HtmlPartial,
                         label: step_configurations.dig(:funding_eligibility_result, :name)

          graph.add_edge from: after, to: :favourite_pet
          graph.add_edge from: :favourite_pet, to: :favourite_sport
          graph.add_edge from: :favourite_sport, to: :funding_eligibility_result
          graph.add_edge from: :funding_eligibility_result, to: before
        end
      end
    end
  end
end
