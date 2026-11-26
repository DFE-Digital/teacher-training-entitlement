module Registrations
  module Journeys
    module Spikes
      class CourseOneWizard < BaseJourneyWizard
        configure_step :cheese,
                       name: "What's your favourite cheese",
                       answer_key: :favourite_cheese,
                       answer_display_name: "Favourite cheese",
                       requires_answer: true,
                       answers: [
                         Registrations::JourneyStep::Choice.new(name: "Cheddar", value: "cheddar"),
                         Registrations::JourneyStep::Choice.new(name: "Brie", value: "brie"),
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
            graph.add_node :cheese,
                           Registrations::JourneyStepTypes::RadioButtons,
                           label: step_config(:cheese).fetch(:name)

            add_shared_wizard(
              SharedFavouritePetAndSportJourneyWizard.new(
                graph:,
                after: :cheese,
                before: :check_answers,
              ),
            )

            graph.add_node :check_answers,
                           Registrations::JourneyStepTypes::CheckAnswers,
                           label: step_config(:check_answers).fetch(:name)
            graph.root :cheese
          end
        end
      end
    end
  end
end
