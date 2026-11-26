module Registrations
  module Journeys
    module Spikes
      class CourseTwoWizard < BaseJourneyWizard
        configure_step :crackers,
                       name: "What's your favourite cracker",
                       answer_key: :favourite_cracker,
                       answer_display_name: "Favourite cracker",
                       requires_answer: true,
                       answers: [
                         JourneyStep::Choice.new(name: "Jacob's Cream cracker", value: "Jacob's Cream cracker"),
                         JourneyStep::Choice.new(name: "Ryvita", value: "Ryvita"),
                       ].freeze
        configure_step :colour,
                       name: "What's your favourite colour",
                       answer_key: :favourite_colour,
                       answer_display_name: "Favourite colour",
                       requires_answer: true,
                       answers: [
                         JourneyStep::Choice.new(name: "Blue", value: "blue"),
                         JourneyStep::Choice.new(name: "Green", value: "green"),
                         JourneyStep::Choice.new(name: "Red", value: "red"),
                       ].freeze
        configure_step :check_answers, name: "Check your answers and submit"
        configure_step :check_answers,
                       services: [
                         {
                           class_name: ->(wizard) { wizard.course.application_creation_service_class_name },
                           execute_point: :after_update,
                         },
                       ]

        def steps_processor
          @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            graph.add_node :crackers,
                           JourneyStepTypes::RadioButtons,
                           label: step_config(:crackers).fetch(:name)

            add_shared_wizard(
              SharedFavouritePetAndSportJourneyWizard.new(
                graph:,
                after: :crackers,
                before: :colour,
              ),
            )

            graph.add_node :colour,
                           JourneyStepTypes::RadioButtons,
                           label: step_config(:colour).fetch(:name)
            graph.add_node :check_answers,
                           JourneyStepTypes::CheckAnswers,
                           label: step_config(:check_answers).fetch(:name)

            graph.root :crackers
            graph.add_edge from: :colour, to: :check_answers
          end
        end
      end
    end
  end
end
