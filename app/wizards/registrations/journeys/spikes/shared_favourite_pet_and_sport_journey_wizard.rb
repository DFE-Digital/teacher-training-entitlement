module Registrations
  module Journeys
    module Spikes
      class SharedFavouritePetAndSportJourneyWizard
        def initialize(add_node:, **)
          @add_node = add_node
        end

        def add_to_graph(graph:, after:, before:)
          favourite_pet = add_node(
            graph,
            name: "What's your favourite pet?",
            slug: "favourite-pet",
            answer_display_name: "Favourite pet",
            state_store_key: "favourite_pet",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: after,
            answers: [
              { name: "Dog", value: "dog" },
              { name: "Cat", value: "cat" },
              { name: "Rabbit", value: "rabbit" },
              { name: "Other", value: "other" },
            ],
          )

          favourite_sport = add_node(
            graph,
            name: "What's your favourite sport?",
            slug: "favourite-sport",
            answer_display_name: "Favourite sport",
            state_store_key: "favourite_sport",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: favourite_pet.slug,
            answers: [
              { name: "Football", value: "football" },
              { name: "Cricket", value: "cricket" },
              { name: "Rugby", value: "rugby" },
              { name: "Tennis", value: "tennis" },
            ],
            services: [
              { class_name: Registrations::Spikes::FavouriteThingsFundingEligibility.name, execute_point: :after_update },
            ],
          )

          funding_result = add_node(
            graph,
            name: "Funding eligibility result",
            slug: "funding-eligibility-result",
            step_class: Registrations::StepDefinitions::HtmlPartial,
            html_partial: "registrations/shared/funding_eligibility_result",
            previous_step_slug: favourite_sport.slug,
          )

          graph.add_edge from: after, to: favourite_pet.graph_id
          graph.add_edge from: favourite_pet.graph_id, to: favourite_sport.graph_id
          graph.add_edge from: favourite_sport.graph_id, to: funding_result.graph_id
          graph.add_edge from: funding_result.graph_id, to: before

          [favourite_pet, favourite_sport, funding_result]
        end

      private

        def add_node(graph, **attributes)
          @add_node.call(graph, **attributes)
        end
      end
    end
  end
end
