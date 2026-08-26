require "rails_helper"

RSpec.describe Admin::RegistrationStepAnswersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "POST /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/answers" do
    before { sign_in_as_admin(super_admin: true) }

    it "adds an answer and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_answers_path(journey, step),
           params: {
             answer_name: "Crisps",
             answer_value: "crispy_bits",
             redirect_path: "/crisps",
             redirect_state_store_key: "snack_path",
           }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.answer_data).to contain_exactly(
        { "name" => "Crisps", "value" => "crispy_bits", "redirect" => { "path" => "/crisps", "state_store_key" => "snack_path" } },
      )
    end
  end

  describe "PATCH /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/answers" do
    before { sign_in_as_admin(super_admin: true) }

    it "updates answer redirects and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "Crisps" },
            ],
          },
        },
      )

      patch admin_registration_journey_registration_step_answers_path(journey, step),
            params: {
              answers: {
                "0" => {
                  name: "Crisps",
                  redirect_state_store_key: "snack_path",
                },
              },
            }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.answer_data).to contain_exactly(
        { "name" => "Crisps", "value" => "crisps", "redirect" => { "state_store_key" => "snack_path" } },
      )
    end
  end

  describe "DELETE /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/answers" do
    before { sign_in_as_admin(super_admin: true) }

    it "deletes an answer and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "Keep this" },
              { "name" => "Delete this", "next_step_id" => 123 },
            ],
          },
        },
      )

      delete admin_registration_journey_registration_step_answers_path(journey, step),
             params: { index: 1 }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.answer_data).to contain_exactly(
        { "name" => "Keep this" },
      )
    end
  end
end
