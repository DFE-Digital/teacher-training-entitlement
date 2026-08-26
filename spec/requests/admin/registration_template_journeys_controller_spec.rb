require "rails_helper"

RSpec.describe Admin::RegistrationTemplateJourneysController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin(super_admin: true) }

  describe "POST /admin/registration-templates/:registration_template_id/journey" do
    it "creates a registration journey from the template" do
      registration_template = RegistrationTemplate.create!(
        name: "NPD course",
        template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
      )

      expect {
        post admin_registration_template_journey_path(registration_template),
             params: {
               registration_journey: {
                 name: "NPD autumn journey",
                 slug: "npd-autumn-journey",
               },
             }
      }.to change(RegistrationJourney, :count).by(1)
        .and change(RegistrationStep, :count).by(11)

      registration_journey = RegistrationJourney.find_by!(slug: "npd-autumn-journey")
      expect(registration_journey.name).to eq("NPD autumn journey")
      expect(response).to redirect_to(admin_registration_journey_path(registration_journey))
    end

    it "does not create a journey when the template cannot be applied" do
      registration_template = RegistrationTemplate.create!(
        name: "NPD course",
        template_generating_service_class: "Kernel",
      )

      expect {
        post admin_registration_template_journey_path(registration_template),
             params: {
               registration_journey: {
                 name: "NPD autumn journey",
                 slug: "npd-autumn-journey",
               },
             }
      }.not_to change(RegistrationJourney, :count)

      expect(response).to redirect_to(admin_registration_template_path(registration_template))
    end
  end
end
