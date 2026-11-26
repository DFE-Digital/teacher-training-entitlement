module Registrations
  module Journeys
    module Spikes
      class CourseOneWizard < BaseJourneyWizard
        def steps_processor
          @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            graph.add_node :cheese, Steps::Spikes::CourseOne::Cheese

            add_shared_wizard(
              SharedFavouritePetAndSportJourneyWizard.new(
                graph:,
                after: :cheese,
                before: :check_answers,
              ),
            )

            graph.add_node :check_answers, Steps::Spikes::CourseOne::CheckAnswers
            graph.root :cheese
          end
        end
      end
    end
  end
end
