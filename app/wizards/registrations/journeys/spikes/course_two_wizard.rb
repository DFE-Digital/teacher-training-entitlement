module Registrations
  module Journeys
    module Spikes
      class CourseTwoWizard < BaseJourneyWizard
        def steps_processor
          @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            graph.add_node :crackers, Steps::Spikes::CourseTwo::Crackers

            add_shared_wizard(
              SharedFavouritePetAndSportJourneyWizard.new(
                graph:,
                after: :crackers,
                before: :colour,
              ),
            )

            graph.add_node :colour, Steps::Spikes::CourseTwo::Colour
            graph.add_node :check_answers, Steps::Spikes::CourseTwo::CheckAnswers

            graph.root :crackers
            graph.add_edge from: :colour, to: :check_answers
          end
        end
      end
    end
  end
end
