module Registrations
  module Journeys
    module Spikes
      class SharedSendFundingEligibilityJourneyWizard
        def initialize(add_node:, connect_from_after: true, **)
          @add_node = add_node
          @connect_from_after = connect_from_after
        end

        def add_to_graph(graph:, after:, before:)
          state_funded_school = add_node(
            graph,
            name: "Do you work in a state-funded school?",
            slug: "state-funded-school",
            answer_display_name: "Work in a state-funded school",
            state_store_key: "state_funded_school",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: after,
            answers: yes_no_answers,
          )

          teaches_send = add_node(
            graph,
            name: "Do you teach children with SEND needs?",
            slug: "teach-children-with-send-needs",
            answer_display_name: "Teach children with SEND needs",
            state_store_key: "teaches_children_with_send_needs",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: state_funded_school.slug,
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
            previous_step_slug: teaches_send.slug,
          )

          graph.add_edge from: after, to: state_funded_school.graph_id if @connect_from_after
          graph.add_edge from: state_funded_school.graph_id, to: teaches_send.graph_id
          graph.add_edge from: teaches_send.graph_id, to: funding_result.graph_id
          graph.add_edge from: funding_result.graph_id, to: before

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
