require "rails_helper"

RSpec.describe Admin::RegistrationStepServicesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "POST /admin/registration-journeys/:journey_id/registration-steps/:registration_step_id/services" do
    before { sign_in_as_admin(super_admin: true) }

    it "updates the service config and redirects back to the registration step edit page" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_services_path(journey, step),
           params: {
             service_class: "Registrations::Courses::Npd::CompletionService",
             execute_point: "after_update",
           }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.services_to_run(execute_point: :after_update))
        .to eq(["Registrations::Courses::Npd::CompletionService"])
    end

    it "updates the service config when the params are nested" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_services_path(journey, step),
           params: {
             registration_step_service: {
               service_class: "Registrations::Courses::Npd::CompletionService",
               execute_point: "before_step",
             },
           }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.services_to_run(execute_point: :before_step))
        .to eq(["Registrations::Courses::Npd::CompletionService"])
    end

    it "defaults to running the service before the step when execute point is blank" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_services_path(journey, step),
           params: {
             service_class: "Registrations::Courses::Npd::CompletionService",
             execute_point: "",
           }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.services_to_run(execute_point: :before_step))
        .to eq(["Registrations::Courses::Npd::CompletionService"])
    end

    it "does not update the service config when the params are invalid" do
      journey = RegistrationJourney.create!(name: "Demo", slug: "demo")
      step = journey.registration_steps.create!(
        name: "Choose a snack",
        slug: "choose-a-snack",
        type: "Radio buttons",
        config: {},
      )

      post admin_registration_journey_registration_step_services_path(journey, step),
           params: {
             service_class: "NotARealService",
             execute_point: "after_update",
           }

      expect(response).to redirect_to(edit_admin_registration_journey_registration_step_path(journey, step))
      expect(step.reload.configured_services).to be_empty
      expect(flash[:alert]).to eq("Select a service and when it should run")
    end
  end
end
