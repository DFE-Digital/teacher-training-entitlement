module Registrations
  module Journeys
    module Spikes
      class SharedSendFundingEligibilityJourneyWizard
        def initialize(graph:, after:, before:)
          @graph = graph
          @after = after
          @before = before
        end

        def add_to_graph
          graph.add_node :state_funded_school, Steps::SharedSendFundingEligibility::StateFundedSchool
          graph.add_node :teach_children_with_send_needs, Steps::SharedSendFundingEligibility::TeachChildrenWithSendNeeds
          graph.add_node :funding_eligibility_result, Steps::SharedSendFundingEligibility::FundingEligibilityResult

          graph.add_edge from: :state_funded_school, to: :teach_children_with_send_needs
          graph.add_edge from: :teach_children_with_send_needs, to: :funding_eligibility_result
          graph.add_edge from: :funding_eligibility_result, to: before
        end

      private

        attr_reader :graph, :after, :before
      end
    end
  end
end
