module Registrations
  module Journeys
    module Spikes
      class SharedFundingEligibilityJourneyWizard
        attr_reader :graph, :after, :before

        def initialize(graph:, after:, before:, add_node:, state_store:, funding_eligibility_class:)
          @graph = graph
          @after = after
          @before = before
          @add_node = add_node
          @state_store = state_store
          @funding_eligibility_class = funding_eligibility_class
        end

        def add_to_graph
          add_funding_eligibility_steps(graph, after:, before:)
        end

      protected

        def add_funding_eligibility_steps(graph, after:, before:)
          teacher_catchment = add_node(
            graph,
            name: "Do you work in England?",
            slug: "teacher-catchment",
            answer_display_name: "Works in England?",
            state_store_key: "teacher_catchment",
            step_class: Registrations::StepDefinitions::RadioButtons,
            required_answer_message: "Select 'Yes' if you work in England",
            services: [
              { class_name: @funding_eligibility_class.name, execute_point: :after_update },
            ],
            answers: [
              { name: "Yes", value: Institution::ENGLAND_SUBDIVISION_CODE, next_step_slug: "work-setting" },
              { name: "No", value: Institution::OTHER, next_step_slug: "ineligible-for-funding" },
            ],
          )

          work_setting = add_node(
            graph,
            name: "Tell us where you work",
            slug: "work-setting",
            state_store_key: "work_setting",
            step_class: Registrations::StepDefinitions::RadioButtons,
            required_answer_message: "Select the setting that you work in",
            texts: [
              {
                text: [
                  "Make sure the information you provide is correct, as your provider will check your details.",
                  "Register using your current workplace details, even if they will change soon.",
                ],
                text_class: "govuk-hint",
              },
            ],
            services: [
              { class_name: @funding_eligibility_class.name, execute_point: :after_update },
            ],
            answers: [
              { name: "State-funded nursery, pre-school, school or academy trust", value: Institution::STATE_FUNDED_INSTITUTION, next_step_slug: "choose-school" },
              { name: "Private nursery, pre-school or school", value: Institution::PRIVATE_INSTITUTION, next_step_slug: "ineligible-for-funding" },
              { name: "Other", value: Institution::OTHER, next_step_slug: "ineligible-for-funding" },
            ],
          )

          choose_school = add_node(
            graph,
            name: "Select your workplace",
            slug: "choose-school",
            state_store_key: "institution_id",
            answer_display_name: "Workplace",
            step_class: Registrations::StepDefinitions::InstitutionChoice,
            required_answer_message: "Enter a workplace name",
            services: [
              { class_name: @funding_eligibility_class.name, execute_point: :after_update },
            ],
            answers: [
              { name: "Not in England", state_store_key: "funding_eligibility_result", value: Registrations::FundingEligibilityConstants::NOT_IN_ENGLAND, next_step_slug: "ineligible-for-funding" },
              { name: "Ineligible setting", state_store_key: "funding_eligibility_result", value: Registrations::FundingEligibilityConstants::INELIGIBLE_SETTING, next_step_slug: "ineligible-for-funding" },
              { name: "Previously funded", state_store_key: "funding_eligibility_result", value: Registrations::FundingEligibilityConstants::PREVIOUSLY_FUNDED, next_step_slug: "ineligible-for-funding" },
              { name: "Funded/ possible funding", state_store_key: "funding_eligibility_result", value: Registrations::FundingEligibilityConstants::FUNDED, next_step_slug: "possible-funding" },
            ],
          )

          possible_funding = add_node(
            graph,
            name: "Funding eligibility result",
            slug: "possible-funding",
            step_class: Registrations::StepDefinitions::FundingEligibilityResult,
            display_on_check_answers: false,
          )

          ineligible_for_funding = add_node(
            graph,
            name: "Funding eligibility result",
            slug: "ineligible-for-funding",
            step_class: Registrations::StepDefinitions::FundingEligibilityResult,
            display_on_check_answers: false,
          )

          funding_your_course = add_node(
            graph,
            name: "How are you funding your course?",
            slug: "funding-your-course",
            state_store_key: "funding",
            answer_display_name: "Course funding",
            step_class: Registrations::StepDefinitions::RadioButtons,
            required_answer_message: "Select an option",
            answers: [
              { name: "My workplace is covering the cost", value: "school" },
              { name: "My trust is paying", value: "trust" },
              { name: "I am paying", value: "self" },
              { name: "My course is being paid for in another way", value: "another", hint: "For example, I am sharing the costs with my workplace" },
            ],
          )

          graph.add_edge from: after, to: :teacher_catchment
          graph.add_multiple_conditional_edges(
            from: :teacher_catchment,
            branches: [
              { when: -> { @state_store["teacher_catchment"] == Institution::ENGLAND_SUBDIVISION_CODE }, then: :work_setting, label: "Works in England" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_multiple_conditional_edges(
            from: :work_setting,
            branches: [
              { when: -> { @state_store["work_setting"] == Institution::STATE_FUNDED_INSTITUTION }, then: :choose_school, label: "State-funded setting" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_multiple_conditional_edges(
            from: :choose_school,
            branches: [
              { when: -> { @state_store["funding_eligibility_result"] == Registrations::FundingEligibilityConstants::FUNDED }, then: :possible_funding, label: "Eligible for funding" },
            ],
            default: :ineligible_for_funding,
          )
          graph.add_edge from: :possible_funding, to: before
          graph.add_edge from: :ineligible_for_funding, to: :funding_your_course
          graph.add_edge from: :funding_your_course, to: before

          [teacher_catchment, work_setting, choose_school, possible_funding, ineligible_for_funding, funding_your_course]
        end

        def add_node(graph, **attributes)
          @add_node.call(graph, **attributes)
        end
      end
    end
  end
end
