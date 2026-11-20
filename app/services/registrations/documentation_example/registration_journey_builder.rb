module Registrations
  module DocumentationExample
    class RegistrationJourneyBuilder < BaseRegistrationJourneyBuilder
      SLUG = "documentation-example".freeze

      attr_reader :registration_journey

      def initialize
        @registration_journey = ::RegistrationJourney.find_or_create_by!(slug: SLUG) do |journey|
          journey.name = "Registration Journey Documentation Example"
        end
      end

      def call
        registration_journey.registration_steps.destroy_all

        start = create_step!(
          name: "Start",
          slug: "start",
          step_class: RegistrationSteps::Plain,
          texts: [
            { text: "This journey demonstrates the available registration step types.", text_class: "govuk-body" },
          ],
        )

        branch_choice = create_step!(
          name: "Choose a path",
          slug: "choose-a-path",
          state_store_key: "documentation_path",
          answer_display_name: "Path",
          step_class: RegistrationSteps::RadioButtons,
          previous_step_id: start.id,
          answers: [
            { name: "Continue to the checkbox example", value: "checkbox" },
            { name: "Skip to the branch end", value: "skip" },
          ],
        )

        checkboxes = create_step!(
          name: "Choose your preferences",
          slug: "choose-preferences",
          state_store_key: "documentation_preferences",
          answer_display_name: "Preferences",
          step_class: RegistrationSteps::Checkboxes,
          previous_step_id: branch_choice.id,
          answers: [
            { name: "Send me updates", value: "updates" },
            { name: "Remember my choices", value: "remember" },
          ],
        )

        short_branch = create_step!(
          name: "Branch without a question",
          slug: "short-branch",
          step_class: RegistrationSteps::Plain,
          previous_step_id: branch_choice.id,
          texts: [
            { text: "This is the shorter branch.", text_class: "govuk-body" },
          ],
        )

        workplace = create_step!(
          name: "Choose your workplace",
          slug: "choose-workplace",
          state_store_key: "institution_id",
          answer_display_name: "Workplace",
          step_class: RegistrationSteps::InstitutionChoice,
          previous_step_id: checkboxes.id,
        )

        information = create_step!(
          name: "More information",
          slug: "more-information",
          step_class: RegistrationSteps::HtmlPartial,
          html_partial: "registrations/documentation_example/more_information",
          previous_step_id: workplace.id,
        )

        course_start = create_step!(
          name: "Choose a course start date",
          slug: "course-start-date",
          state_store_key: "course_cohort_ecf_id",
          answer_display_name: "Course start date",
          step_class: RegistrationSteps::ViewComponent,
          view_component: "Registrations::CourseStartDateComponent",
          previous_step_id: information.id,
        )

        create_step!(
          name: "Check your answers",
          slug: "check-answers",
          step_class: RegistrationSteps::CheckAnswers,
          previous_step_id: course_start.id,
          texts: [
            { text: "Review the information you have entered.", text_class: "govuk-body" },
          ],
        )

        branch_choice.set_answers!(
          answers: [
            { name: "Continue to the checkbox example", value: "checkbox", next_step_id: checkboxes.id },
            { name: "Skip to the branch end", value: "skip", next_step_id: short_branch.id },
          ],
        )
        branch_choice.update!(branch_join_step: workplace)
      end
    end
  end
end
