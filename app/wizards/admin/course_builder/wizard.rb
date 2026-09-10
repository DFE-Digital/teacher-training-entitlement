require "dfe/wizard/steps_processor/base"

module Admin
  module CourseBuilder
    class Wizard
      include DfE::Wizard

      STEPS = {
        course_details: Steps::CourseDetails,
        milestones: Steps::Milestones,
        lead_providers: Steps::LeadProviders,
        contract_financials: Steps::ContractFinancials,
        check_answers: Steps::CheckAnswers,
      }.freeze

      STEP_TITLES = {
        course_details: "Course details",
        milestones: "Milestones",
        lead_providers: "Lead providers",
        contract_financials: "Contract financials",
        check_answers: "Check answers",
      }.freeze

      def steps_processor
        DfE::Wizard::StepsProcessor::Graph.draw(self) do |graph|
          STEPS.each do |step_name, step_class|
            graph.add_node step_name, step_class
          end

          graph.root :course_details
          graph.add_edge from: :course_details, to: :milestones
          graph.add_edge from: :milestones, to: :lead_providers
          graph.add_edge from: :lead_providers, to: :contract_financials
          graph.add_edge from: :contract_financials, to: :check_answers
        end
      end

      def steps_operator
        DfE::Wizard::StepsOperator::Builder.draw(wizard: self) {}
      end

      def route_strategy
        DfE::Wizard::RouteStrategy::DynamicRoutes.new(
          state_store:,
          path_builder: ->(step_id, _state_store, _helpers, _options) { "/admin/course-builder/#{step_id.to_s.dasherize}" },
        )
      end

      def step_title
        STEP_TITLES.fetch(current_step_name)
      end
    end
  end
end
