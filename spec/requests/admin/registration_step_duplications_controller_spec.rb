require "rails_helper"

RSpec.describe Admin::RegistrationStepDuplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "POST /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/duplication" do
    before { sign_in_as_admin(super_admin: true) }

    it "duplicates the step immediately after its source and redirects to the journey" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      source = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Coffee", "next_step_id" => 123 }],
          },
          "branch_join_step_id" => 456,
        },
      )
      following_step = journey.registration_steps.create!(
        name: "Check answers",
        slug: "check-answers",
        type: "Check answers",
        order: 2,
        config: {},
      )

      expect {
        post admin_registration_journey_registration_step_duplication_path(journey, source)
      }.to change(journey.registration_steps, :count).by(1)

      expect(response).to redirect_to(admin_registration_journey_path(journey))
      duplicate = journey.registration_steps.find_by!(slug: "choose-a-drink-copy")
      expect(duplicate).to have_attributes(
        name: "Choose a drink copy",
        type: source.type,
        order: 2,
        config: source.config,
      )
      expect(following_step.reload.order).to eq(3)
    end

    it "generates a distinct name and slug for subsequent copies" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      source = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      journey.registration_steps.create!(
        name: "Choose a drink copy",
        slug: "choose-a-drink-copy",
        type: "Radio buttons",
        order: 2,
        config: {},
      )

      post admin_registration_journey_registration_step_duplication_path(journey, source)

      expect(journey.registration_steps.find_by!(slug: "choose-a-drink-copy-2").name)
        .to eq("Choose a drink copy 2")
    end
  end
end
