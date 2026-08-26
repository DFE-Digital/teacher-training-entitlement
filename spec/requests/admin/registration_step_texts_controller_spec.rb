require "rails_helper"

RSpec.describe Admin::RegistrationStepTextsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "POST /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/texts" do
    before { sign_in_as_admin(super_admin: true) }

    it "adds text and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_texts_path(journey, step),
           params: { text: "Some useful intro text", text_size: "m" }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.text_data).to contain_exactly(
        { "text" => "Some useful intro text", "text_size" => "m" },
      )
    end

    it "defaults the text size to medium when no size is selected" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_texts_path(journey, step),
           params: { text: "Some useful intro text" }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.text_data).to contain_exactly(
        { "text" => "Some useful intro text", "text_size" => "m" },
      )
    end
  end

  describe "DELETE /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/texts" do
    before { sign_in_as_admin(super_admin: true) }

    it "deletes text and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {
          "radio_buttons" => {
            "text" => [
              { "text" => "Keep this", "text_size" => "m" },
              { "text" => "Delete this", "text_size" => "s" },
            ],
          },
        },
      )

      delete admin_registration_journey_registration_step_texts_path(journey, step),
             params: { index: 1 }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.text_data).to contain_exactly(
        { "text" => "Keep this", "text_size" => "m" },
      )
    end
  end
end
