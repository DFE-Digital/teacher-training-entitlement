require "rails_helper"

RSpec.describe Admin::RegistrationStepCustomStepsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "POST /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/custom-step" do
    before { sign_in_as_admin(super_admin: true) }

    it "updates the custom step class and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Cool step",
        slug: "cool-step",
        type: "Custom step",
        config: {},
      )

      post admin_registration_journey_registration_step_custom_step_path(journey, step),
           params: { custom_step: "Forms::RegisterForThing::CoolStepForm" }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.custom_step_class_name).to eq("Forms::RegisterForThing::CoolStepForm")
    end
  end
end
