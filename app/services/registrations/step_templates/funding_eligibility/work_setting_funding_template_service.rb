module Registrations
  module StepTemplates
    module FundingEligibility
      class WorkSettingFundingTemplateService < BaseStepTemplateService
        def call
          teacher_catchment = create_step(
            name: "Do you work in England?",
            slug: "teacher-catchment",
            type: "Radio buttons",
            order: 1,
            answer_key: "teacher_catchment",
            answers: [
              { "name" => "England", "value" => "England" },
              { "name" => "Not England", "value" => "Not England" },
            ],
          )

          workplace = create_step(
            name: "Select your workplace",
            slug: "select-your-workplace",
            type: "Choose institution",
            order: 2,
            answer_key: "institution_id",
            previous_step_id: teacher_catchment.id,
          )

          funding_eligibility_results = create_step(
            name: "Funding eligibility results",
            slug: "funding-eligibility-results",
            type: RegistrationSteps::CustomView::TYPE,
            order: 3,
            previous_step_id: workplace.id,
          )
          funding_eligibility_results.set_custom_view!(
            custom_view_class_name: "Registrations::NpdFundingEligibilityResultsComponent",
          )
          funding_eligibility_results.add_service!(
            class_name: "Registrations::FundingEligibility::NpdService",
            execute_point: :before_show,
          )

          create_step(
            name: "Check answers",
            slug: "check-answers",
            type: "Check answers",
            order: 4,
            previous_step_id: funding_eligibility_results.id,
          )

          teacher_catchment.set_answers!(
            answers: [
              { "name" => "England", "value" => "England" },
              { "name" => "Not England", "value" => "Not England", "next_step_id" => funding_eligibility_results.id },
            ],
          )
        end

      private

        def create_step(name:, slug:, type:, order:, answer_key: nil, answers: [], previous_step_id: nil)
          type_as_param = type.underscore.parameterize.underscore
          config = {
            type_as_param => {
              "answers" => answers,
            },
          }
          config["previous_step_id"] = previous_step_id if previous_step_id

          registration_journey.registration_steps.create!(
            name:,
            slug:,
            type:,
            order:,
            answer_key:,
            config:,
          )
        end
      end
    end
  end
end
