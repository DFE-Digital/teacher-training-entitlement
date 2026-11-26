module Registrations
  module Journeys
    class ExcellenceInReceptionWizard < BaseJourneyWizard
      configure_step :course_start_date,
                     name: "Course start",
                     answer_key: :course_cohort_ecf_id,
                     answer_display_name: "Course start",
                     requires_answer: true,
                     required_answer_message: "Choose your course start date"
      configure_step :cannot_register_yet,
                     name: "You cannot register yet",
                     partial_name: "registrations/excellence_in_reception/email_updates_signup"
      configure_step :choose_your_provider,
                     name: "Select your training provider",
                     answer_key: :lead_provider_id,
                     answer_display_name: "Provider",
                     required_answer_message: "Choose a provider",
                     answers: lambda { |_wizard|
                       LeadProvider.alphabetical.map do |provider|
                         JourneyStep::Choice.new(name: provider.name, value: provider.id.to_s)
                       end
                     }
      configure_step :teacher_catchment,
                     name: "Do you work in England?",
                     answer_key: :teacher_catchment,
                     answer_display_name: "Works in England?",
                     required_answer_message: "Select 'Yes' if you work in England",
                     services: [
                       { class_name: ->(wizard) { wizard.course.funding_eligibility_service_class }, execute_point: :after_update },
                     ],
                     answers: [
                       JourneyStep::Choice.new(name: "Yes", value: Institution::ENGLAND_SUBDIVISION_CODE),
                       JourneyStep::Choice.new(name: "No", value: Institution::OTHER),
                     ]
      configure_step :work_setting,
                     name: "Tell us where you work",
                     answer_key: :work_setting,
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
                       { class_name: ->(wizard) { wizard.course.funding_eligibility_service_class }, execute_point: :after_update },
                     ],
                     answers: [
                       JourneyStep::Choice.new(name: "State-funded nursery, pre-school, school or academy trust", value: Institution::STATE_FUNDED_INSTITUTION),
                       JourneyStep::Choice.new(name: "Private nursery, pre-school or school", value: Institution::PRIVATE_INSTITUTION),
                       JourneyStep::Choice.new(name: "Other", value: Institution::OTHER),
                     ]
      configure_step :choose_school,
                     name: "Select your workplace",
                     answer_key: :institution_id,
                     answer_display_name: "Workplace",
                     required_answer_message: "Enter a workplace name",
                     services: [
                       { class_name: ->(wizard) { wizard.course.funding_eligibility_service_class }, execute_point: :after_update },
                     ]
      configure_step :possible_funding,
                     name: "Funding eligibility result",
                     display_on_check_answers: false
      configure_step :ineligible_for_funding,
                     name: "Funding eligibility result",
                     display_on_check_answers: false
      configure_step :funding_your_course,
                     name: "How are you funding your course?",
                     answer_key: :funding,
                     answer_display_name: "Course funding",
                     required_answer_message: "Select an option",
                     answers: [
                       JourneyStep::Choice.new(name: "My workplace is covering the cost", value: "school"),
                       JourneyStep::Choice.new(name: "My trust is paying", value: "trust"),
                       JourneyStep::Choice.new(name: "I am paying", value: "self"),
                       JourneyStep::Choice.new(name: "My course is being paid for in another way", value: "another", hint: "For example, I am sharing the costs with my workplace"),
                     ]
      configure_step :share_provider,
                     name: "Sharing your NPD information",
                     answer_key: :can_share_choices,
                     requires_answer: true,
                     multiple_answers: false,
                     display_on_check_answers: false,
                     required_answer_message: "You must agree to share data with providers to continue",
                     answers: [JourneyStep::Choice.new(name: "Yes, I agree to share my information", value: "1")],
                     texts: [
                       {
                         text: ["All the information you enter for your NPD registration will be shared with external organisations including auditors, evaluators, relevant bodies and training providers — this allows your provider to register you onto their course."],
                         text_class: "govuk-body",
                       },
                       {
                         text: ["For more information about who we share your data with read our <a href=\"https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers#register-NPQ\">privacy notice</a>."],
                         text_class: "govuk-body",
                       },
                       {
                         text: ["If you do not agree to share your information you will not be able to progress with your NPD course."],
                         text_class: "govuk-body",
                       },
                     ]
      configure_step :check_answers,
                     name: "Check your answers and submit",
                     redirect_path: "/applications/:application_ecf_id",
                     services: [
                       { class_name: ->(wizard) { wizard.course.application_creation_service_class_name }, execute_point: :after_update },
                     ]

      def steps_processor
        @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
          graph.add_node :course_start_date,
                         JourneyStepTypes::CourseStartDate,
                         label: step_config(:course_start_date).fetch(:name)
          graph.add_node :cannot_register_yet,
                         JourneyStepTypes::HtmlPartial,
                         label: step_config(:cannot_register_yet).fetch(:name)
          graph.add_node :choose_your_provider,
                         JourneyStepTypes::RadioButtons,
                         label: step_config(:choose_your_provider).fetch(:name)
          graph.add_node :teacher_catchment,
                         JourneyStepTypes::RadioButtons,
                         label: step_config(:teacher_catchment).fetch(:name)
          graph.add_node :work_setting,
                         JourneyStepTypes::RadioButtons,
                         label: step_config(:work_setting).fetch(:name)
          graph.add_node :choose_school,
                         JourneyStepTypes::InstitutionChoice,
                         label: step_config(:choose_school).fetch(:name)
          graph.add_node :possible_funding,
                         JourneyStepTypes::FundingEligibilityResult,
                         label: step_config(:possible_funding).fetch(:name)
          graph.add_node :ineligible_for_funding,
                         JourneyStepTypes::FundingEligibilityResult,
                         label: step_config(:ineligible_for_funding).fetch(:name)
          graph.add_node :funding_your_course,
                         JourneyStepTypes::RadioButtons,
                         label: step_config(:funding_your_course).fetch(:name)
          graph.add_node :share_provider,
                         JourneyStepTypes::Checkboxes,
                         label: step_config(:share_provider).fetch(:name)
          graph.add_node :check_answers,
                         JourneyStepTypes::CheckAnswers,
                         label: step_config(:check_answers).fetch(:name)

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
