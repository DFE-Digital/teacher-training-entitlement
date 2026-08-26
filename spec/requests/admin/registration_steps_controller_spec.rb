require "rails_helper"

RSpec.describe Admin::RegistrationStepsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "PATCH /admin/registration-journeys/:registration_journey_id/registration-steps/:id" do
    before { sign_in_as_admin(super_admin: true) }

    it "updates redirect configuration" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Check answers",
        slug: "check-answers",
        type: "Check answers",
        config: {},
      )

      patch admin_registration_journey_registration_step_path(journey, step),
            params: {
              registration_step: {
                name: "Check answers",
                slug: "check-answers",
                type: "Check answers",
                answer_key: "check_answers_result",
                redirect_path: "/applications/123",
                redirect_state_store_key: "application_path",
              },
            }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.answer_key).to eq("check_answers_result")
      expect(step.reload.redirect_path).to eq("/applications/123")
      expect(step.redirect_state_store_key).to eq("application_path")
    end
  end
end
