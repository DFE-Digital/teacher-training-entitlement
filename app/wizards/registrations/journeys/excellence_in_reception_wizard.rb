module Registrations
  module Journeys
    class ExcellenceInReceptionWizard < BaseJourneyWizard
      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          course_start_date = add_node(
            graph,
            name: "Course start",
            slug: "course-start-date",
            state_store_key: "course_cohort_ecf_id",
            answer_display_name: "Course start",
            step_class: Registrations::StepDefinitions::ViewComponent,
            view_component: "Registrations::CourseStartDateComponent",
            requires_answer: true,
            required_answer_message: "Choose your course start date",
            answers: [
              { name: "Start later", value: "later", next_step_slug: "cannot-register-yet" },
            ],
          )

          add_node(
            graph,
            name: "You cannot register yet",
            slug: "cannot-register-yet",
            step_class: Registrations::StepDefinitions::HtmlPartial,
            html_partial: "registrations/excellence_in_reception/email_updates_signup",
            previous_step_slug: course_start_date.slug,
          )

          choose_provider = add_node(
            graph,
            name: "Select your training provider",
            slug: "choose-your-provider",
            state_store_key: "lead_provider_id",
            answer_display_name: "Provider",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: course_start_date.slug,
            required_answer_message: "Choose a provider",
            answers: LeadProvider.alphabetical.map do |provider|
              { name: provider.name, value: provider.id.to_s }
            end,
          )

          teacher_catchment = add_node(
            graph,
            name: "Do you work in England?",
            slug: "teacher-catchment",
            answer_display_name: "Works in England?",
            state_store_key: "teacher_catchment",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: choose_provider.slug,
            required_answer_message: "Select 'Yes' if you work in England",
            services: [
              { class_name: course.funding_eligibility_service_class.name, execute_point: :after_update },
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
            previous_step_slug: teacher_catchment.slug,
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
              { class_name: course.funding_eligibility_service_class.name, execute_point: :after_update },
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
            previous_step_slug: work_setting.slug,
            required_answer_message: "Enter a workplace name",
            services: [
              { class_name: course.funding_eligibility_service_class.name, execute_point: :after_update },
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
            step_class: Registrations::StepDefinitions::ViewComponent,
            view_component: "Registrations::NpdFundingEligibilityResultsComponent",
            previous_step_slug: choose_school.slug,
            display_on_check_answers: false,
          )

          ineligible_for_funding = add_node(
            graph,
            name: "Funding eligibility result",
            slug: "ineligible-for-funding",
            step_class: Registrations::StepDefinitions::ViewComponent,
            view_component: "Registrations::NpdFundingEligibilityResultsComponent",
            previous_step_slug: work_setting.slug,
            display_on_check_answers: false,
          )

          add_node(
            graph,
            name: "How are you funding your course?",
            slug: "funding-your-course",
            state_store_key: "funding",
            answer_display_name: "Course funding",
            step_class: Registrations::StepDefinitions::RadioButtons,
            previous_step_slug: ineligible_for_funding.slug,
            required_answer_message: "Select an option",
            answers: [
              { name: "My workplace is covering the cost", value: "school" },
              { name: "My trust is paying", value: "trust" },
              { name: "I am paying", value: "self" },
              { name: "My course is being paid for in another way", value: "another", hint: "For example, I am sharing the costs with my workplace" },
            ],
          )

          share_provider = add_node(
            graph,
            name: "Sharing your NPD information",
            slug: "share-provider",
            state_store_key: "can_share_choices",
            step_class: Registrations::StepDefinitions::Checkboxes,
            requires_answer: true,
            previous_step_slug: possible_funding.slug,
            config: { checkboxes: { multiple_answers: false } },
            answers: [{ name: "Yes, I agree to share my information", value: "1" }],
            display_on_check_answers: false,
            required_answer_message: "You must agree to share data with providers to continue",
            texts: [
              {
                text: "All the information you enter for your NPD registration will be shared with external organisations including auditors, evaluators, relevant bodies and training providers — this allows your provider to register you onto their course.",
                text_class: "govuk-body",
              },
              {
                text: "For more information about who we share your data with read our <a href=\"https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers#register-NPQ\">privacy notice</a>.",
                text_class: "govuk-body",
              },
              {
                text: "If you do not agree to share your information you will not be able to progress with your NPD course.",
                text_class: "govuk-body",
              },
            ],
          )

          add_node(
            graph,
            name: "Check your answers and submit",
            slug: "check-answers",
            step_class: Registrations::StepDefinitions::CheckAnswers,
            redirect_path: "/applications/:ecf_id",
            redirect_state_store_key: "application_ecf_id",
            previous_step_slug: share_provider.slug,
            services: [
              { class_name: course.application_creation_service_class_name, execute_point: :after_update },
            ],
          )

          teacher_catchment.branch_join_step_slug = share_provider.slug
          work_setting.branch_join_step_slug = share_provider.slug

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
              { when: -> { state_store["funding_eligibility_result"] == Registrations::FundingEligibilityConstants::FUNDED }, then: :possible_funding, label: "Eligible for funding" },
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
