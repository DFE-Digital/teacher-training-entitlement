module Registrations
  module Journeys
    module Spikes
      class SharedSendFundingEligibilityJourneyWizard
        attr_reader :graph, :after, :before

        def initialize(graph:, after:, before:, add_node:, connect_from_after: true)
          @graph = graph
          @after = after
          @before = before
          @add_node = add_node
          @connect_from_after = connect_from_after
        end

        def add_to_graph
          state_funded_school = add_node(
            graph,
            name: "Do you work in a state-funded school?",
            slug: "state-funded-school",
            answer_display_name: "Work in a state-funded school",
            state_store_key: "state_funded_school",
            step_class: Registrations::StepDefinitions::RadioButtons,
            answers: yes_no_answers,
          )

          teaches_send = add_node(
            graph,
            name: "Do you teach children with SEND needs?",
            slug: "teach-children-with-send-needs",
            answer_display_name: "Teach children with SEND needs",
            state_store_key: "teaches_children_with_send_needs",
            step_class: Registrations::StepDefinitions::RadioButtons,
            answers: yes_no_answers,
            services: [
              { class_name: Registrations::SendInclusivePractice::FundingEligibility.name, execute_point: :after_update },
            ],
          )

          funding_result = add_node(
            graph,
            name: "Funding eligibility result",
            slug: "funding-eligibility-result",
            step_class: Registrations::StepDefinitions::HtmlPartial,
            html_partial: "registrations/shared/funding_eligibility_result",
          )

          graph.add_edge from: after, to: :state_funded_school if @connect_from_after
          graph.add_edge from: :state_funded_school, to: :teach_children_with_send_needs
          graph.add_edge from: :teach_children_with_send_needs, to: :funding_eligibility_result
          graph.add_edge from: :funding_eligibility_result, to: before

          [state_funded_school, teaches_send, funding_result]
        end

      private

        def yes_no_answers
          [
            { name: "Yes", value: "yes" },
            { name: "No", value: "no" },
          ]
        end

        def add_node(graph, **attributes)
          @add_node.call(graph, **attributes)
        end
      end
    end
  end
end
