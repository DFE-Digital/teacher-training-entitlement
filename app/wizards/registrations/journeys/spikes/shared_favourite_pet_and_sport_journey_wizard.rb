module Registrations
  module Journeys
    module Spikes
      class SharedFavouritePetAndSportJourneyWizard
        def initialize(graph:, after:, before:)
          @graph = graph
          @after = after
          @before = before
        end

        def add_to_graph
          graph.add_node :favourite_pet, Steps::SharedFavouritePetAndSport::FavouritePet
          graph.add_node :favourite_sport, Steps::SharedFavouritePetAndSport::FavouriteSport
          graph.add_node :funding_eligibility_result, Steps::SharedFavouritePetAndSport::FundingEligibilityResult

          graph.add_edge from: after, to: :favourite_pet
          graph.add_edge from: :favourite_pet, to: :favourite_sport
          graph.add_edge from: :favourite_sport, to: :funding_eligibility_result
          graph.add_edge from: :funding_eligibility_result, to: before
        end

      private

        attr_reader :graph, :after, :before
      end
    end
  end
end
