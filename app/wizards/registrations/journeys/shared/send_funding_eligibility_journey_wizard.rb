module Registrations
  module Journeys
    module Shared
      class SendFundingEligibilityJourneyWizard
        def initialize(graph:, after:, before:)
          @graph = graph
          @after = after
          @before = before
        end

        def add_to_graph
          graph.add_node :placeholder, Steps::SharedSendFundingEligibility::Placeholder
          graph.add_edge from: :placeholder, to: before
        end

      private

        attr_reader :graph, :after, :before
      end
    end
  end
end
