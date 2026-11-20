module Registrations
  module ExcellenceInReception
    class RegistrationJourneyBuilder < BaseRegistrationJourneyBuilder
      attr_reader :registration_journey

      def initialize
        @registration_journey = ::RegistrationJourney.create!(
          name: Courses::ExcellenceInReception::NAME,
          slug: Courses::ExcellenceInReception::JOURNEY_SLUG,
          course: Course.reception,
        )
      end

      def call
        start = create_step!(
          name: "Start",
          slug: "start",
          answer_display_name: "Start",
          step_class: RegistrationSteps::HtmlPartial,
          html_partial: "registrations/excellence_in_reception/start",
        )

        course_start_date = create_step!(
          name: "Course start",
          slug: "course-start-date",
          state_store_key: "course_cohort_ecf_id",
          answer_display_name: "Course start",
          step_class: RegistrationSteps::ViewComponent,
          view_component: "Registrations::CourseStartDateComponent",
          previous_step_id: start.id,
          requires_answer: true,
          required_answer_message: "Choose your course start date",
        )

        cannot_register_yet = create_step!(
          name: "You cannot register yet",
          slug: "cannot-register-yet",
          step_class: RegistrationSteps::HtmlPartial,
          html_partial: "registrations/excellence_in_reception/email_updates_signup",
          previous_step_id: course_start_date.id,
        )

        # For the course cohort dates we can just go to the next default step
        # but for the "start later" option we want to redirect to cannot register step
        course_start_date.set_answers!(answers: [{ name: "Start later", value: "later", next_step_id: cannot_register_yet.id }])

        choose_your_provider = create_step!(
          name: "Select your training provider",
          slug: "choose-your-provider",
          state_store_key: "lead_provider_id",
          answer_display_name: "Provider",
          step_class: RegistrationSteps::RadioButtons,
          previous_step_id: course_start_date.id,
          answers: LeadProvider.alphabetical.map do |lead_provider|
            { "name" => lead_provider.name, "value" => lead_provider.id.to_s }
          end,
          required_answer_message: "Choose a provider",
        )

        teacher_catchment = create_step!(
          name: "Do you work in England?",
          slug: "teacher-catchment",
          answer_display_name: "Works in England?",
          state_store_key: "teacher_catchment",
          step_class: RegistrationSteps::RadioButtons,
          previous_step_id: choose_your_provider.id,
          answers: [
            { "name" => "Yes", "value" => Questionnaires::TeacherCatchment::ENGLAND },
            { "name" => "No", "value" => Questionnaires::TeacherCatchment::NOT_ENGLAND },
          ],
          services: [
            { class_name: Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, execute_point: :after_update },
          ],
          required_answer_message: "Select 'Yes' if you work in England",
        )

        work_setting = create_step!(
          name: "Tell us where you work",
          slug: "work-setting",
          state_store_key: "work_setting",
          step_class: RegistrationSteps::RadioButtons,
          previous_step_id: teacher_catchment.id,
          answers: [
            { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => Institution::STATE_FUNDED_INSTITUTION },
            { "name" => "Private nursery, pre-school or school", "value" => Institution::PRIVATE_INSTITUTION },
            { "name" => "Other", "value" => Institution::OTHER },
          ],
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
            { class_name: Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, execute_point: :after_update },
          ],
          required_answer_message: "Select the setting that you work in",
        )

        choose_school = create_step!(
          name: "Select your workplace",
          slug: "choose-school",
          state_store_key: "institution_id",
          answer_display_name: "Workplace",
          step_class: RegistrationSteps::InstitutionChoice,
          previous_step_id: work_setting.id,
          services: [
            { class_name: Courses::ExcellenceInReception::FUNDING_ELIGIBILITY_CLASS.name, execute_point: :after_update },
          ],
          required_answer_message: "Enter a workplace name",
        )

        possible_funding = create_step!(
          name: "Funding eligibility result",
          slug: "possible-funding",
          step_class: RegistrationSteps::ViewComponent,
          view_component: "Registrations::NpdFundingEligibilityResultsComponent",
          previous_step_id: choose_school.id,
          display_on_check_answers: false,
        )

        ineligible_for_funding = create_step!(
          name: "Funding eligibility result",
          slug: "ineligible-for-funding",
          step_class: RegistrationSteps::ViewComponent,
          view_component: "Registrations::NpdFundingEligibilityResultsComponent",
          previous_step_id: work_setting.id,
          display_on_check_answers: false,
        )

        choose_school.set_answers!(
          answers: [
            {
              name: "Not in England",
              state_store_key: "funding_eligibility_result",
              value: Registrations::ExcellenceInReception::FundingEligibility::NOT_IN_ENGLAND,
              next_step_id: ineligible_for_funding.id,
            },
            {
              name: "Ineligible setting",
              state_store_key: "funding_eligibility_result",
              value: Registrations::ExcellenceInReception::FundingEligibility::INELIGIBLE_SETTING,
              next_step_id: ineligible_for_funding.id,
            },
            {
              name: "Previously funded",
              state_store_key: "funding_eligibility_result",
              value: Registrations::ExcellenceInReception::FundingEligibility::PREVIOUSLY_FUNDED,
              next_step_id: ineligible_for_funding.id,
            },
            {
              name: "Funded/ possible funding",
              state_store_key: "funding_eligibility_result",
              value: Registrations::ExcellenceInReception::FundingEligibility::FUNDED,
              next_step_id: possible_funding.id,
            },
          ],
        )

        create_step!(
          name: "How are you funding your course?",
          slug: "funding-your-course",
          state_store_key: "funding",
          answer_display_name: "Course funding",
          step_class: RegistrationSteps::RadioButtons,
          previous_step_id: ineligible_for_funding.id,
          answers: [
            { "name" => "My workplace is covering the cost", "value" => "school" },
            { "name" => "My trust is paying", "value" => "trust" },
            { "name" => "I am paying", "value" => "self" },
            { "name" => "My course is being paid for in another way", "value" => "another", "hint" => "For example, I am sharing the costs with my workplace" },
          ],
          required_answer_message: "Select an option",
        )

        share_provider = create_step!(
          name: "Sharing your NPD information",
          slug: "share-provider",
          state_store_key: "can_share_choices",
          step_class: RegistrationSteps::Checkboxes,
          requires_answer: true,
          previous_step_id: possible_funding.id,
          config: { checkboxes: { multiple_answers: false } },
          answers: [
            { "name" => "Yes, I agree to share my information",
              "value" => "1" },
          ],
          display_on_check_answers: false,
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
          required_answer_message: "You must agree to share data with providers to continue",
        )

        create_step!(
          name: "Check your answers and submit",
          slug: "check-answers",
          step_class: RegistrationSteps::CheckAnswers,
          redirect_path: "/applications/:ecf_id",
          redirect_state_store_key: "application_ecf_id",
          previous_step_id: share_provider.id,
          services: [
            { class_name: Courses::ExcellenceInReception::APPLICATION_COMPLETION_CLASS.name, execute_point: :after_update },
          ],
        )

        teacher_catchment.set_answers!(
          answers: [
            { "name" => "Yes", "value" => Institution::ENGLAND_SUBDIVISION_CODE, "next_step_id" => work_setting.id },
            { "name" => "No", "value" => Institution::OTHER, "next_step_id" => ineligible_for_funding.id },
          ],
        )
        work_setting.set_answers!(
          answers: [
            { "name" => "State-funded nursery, pre-school, school or academy trust", "value" => Institution::STATE_FUNDED_INSTITUTION, "next_step_id" => choose_school.id },
            { "name" => "Private nursery, pre-school or school", "value" => Institution::PRIVATE_INSTITUTION, "next_step_id" => ineligible_for_funding.id },
            { "name" => "Other", "value" => Institution::OTHER, "next_step_id" => ineligible_for_funding.id },
          ],
        )

        teacher_catchment.branch_join_step_id = share_provider.id
        work_setting.branch_join_step_id = share_provider.id
        teacher_catchment.save!
        work_setting.save!
      end
    end
  end
end
