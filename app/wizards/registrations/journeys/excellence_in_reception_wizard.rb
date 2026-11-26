module Registrations
  module Journeys
    class ExcellenceInReceptionWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :course_start_date, Steps::ExcellenceInReception::CourseStartDate
          graph.add_node :cannot_register_yet, Steps::ExcellenceInReception::CannotRegisterYet
          graph.add_node :choose_your_provider, Steps::ExcellenceInReception::ChooseYourProvider
          graph.add_node :teacher_catchment, Steps::ExcellenceInReception::TeacherCatchment
          graph.add_node :work_setting, Steps::ExcellenceInReception::WorkSetting
          graph.add_node :choose_school, Steps::ExcellenceInReception::ChooseSchool
          graph.add_node :possible_funding, Steps::ExcellenceInReception::PossibleFunding
          graph.add_node :ineligible_for_funding, Steps::ExcellenceInReception::IneligibleForFunding
          graph.add_node :funding_your_course, Steps::ExcellenceInReception::FundingYourCourse
          graph.add_node :share_provider, Steps::ExcellenceInReception::ShareProvider
          graph.add_node :check_answers, Steps::ExcellenceInReception::CheckAnswers

          graph.root :course_start_date
          graph.add_multiple_conditional_edges(
            from: :course_start_date,
            branches: [
              { when: -> { state_store["course_cohort_ecf_id"] == "later" }, then: :cannot_register_yet, label: "Start later" },
            ],
            default: :choose_your_provider,
          )
          graph.add_edge from: :choose_your_provider, to: :teacher_catchment
          graph.add_multiple_conditional_edges(
            from: :teacher_catchment,
            branches: [
              { when: -> { state_store["teacher_catchment"] == Institution::ENGLAND_SUBDIVISION_CODE }, then: :work_setting, label: "Works in England" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_multiple_conditional_edges(
            from: :work_setting,
            branches: [
              { when: -> { state_store["work_setting"] == Institution::STATE_FUNDED_INSTITUTION }, then: :choose_school, label: "State-funded setting" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_multiple_conditional_edges(
            from: :choose_school,
            branches: [
              { when: -> { state_store["funding_eligibility_result"] == FundingEligibilityConstants::FUNDED }, then: :possible_funding, label: "Eligible for funding" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_edge from: :possible_funding, to: :share_provider
          graph.add_edge from: :ineligible_for_funding, to: :funding_your_course
          graph.add_edge from: :funding_your_course, to: :share_provider
          graph.add_edge from: :share_provider, to: :check_answers
        end
      end
    end
  end
end
