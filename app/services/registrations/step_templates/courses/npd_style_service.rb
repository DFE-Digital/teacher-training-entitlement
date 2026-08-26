module Registrations
  module StepTemplates
    module Courses
      class NpdStyleService < BaseStepTemplateService
        def call
          starting_order = registration_journey.registration_steps.maximum(:order).to_i

          teacher_catchment = RegistrationStep.create!(
            name: "Teacher Catchment",
            type: "Radio buttons",
            order: starting_order + 1,
            config: {
              "radio_buttons" => {
                "answers" => [
                  { "name" => "England" },
                  { "name" => "Not England" },
                ],
              },
            },
            registration_journey:,
          )

          RegistrationStep.create!(
            name: "Tell us where you work",
            type: "Radio buttons",
            order: starting_order + 2,
            config: {
              "radio_buttons" => {
                "answers" => [
                  { "name" => "State-funded nursery, pre-school, school or academy trust" },
                  { "name" => "Private nursery, pre-school or school" },
                  { "name" => "Other" },
                ],
              },
            },
            registration_journey:,
          )

          RegistrationStep.create!(
            name: "Select your workplace",
            type: "Choose institution",
            order: starting_order + 3,
            registration_journey:,
          )

          step = RegistrationStep.create!(
            name: "Funding eligibility results",
            type: RegistrationSteps::CustomView::TYPE,
            order: starting_order + 4,
            registration_journey:,
          )
          step.set_custom_view!(custom_view_class_name: "Registrations::NpdFundingEligibilityResultsComponent")

          teacher_catchment.set_answers!(
            answers: [
              { "name" => "England" },
              { "name" => "Not England", "next_step_id" => step.id },
            ],
          )

          step.add_service!(class_name: "Registrations::FundingEligibility::NpdService",
                            execute_point: :before_show)

          RegistrationStep.create!(
            name: "Choose your provider",
            answer_key: "lead_provider_id",
            type: "Radio buttons",
            order: starting_order + 5,
            config: {
              "radio_buttons" => {
                "answers" => LeadProvider.all.map { |lp| { "name" => lp.name, "value" => lp.id.to_s } },
              },
            },
            registration_journey:,
          )

          RegistrationStep.create!(
            name: "Check answers",
            type: "Check answers",
            order: starting_order + 6,
            registration_journey:,
          )
        end
      end
    end
  end
end
