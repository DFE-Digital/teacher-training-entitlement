require "rails_helper"

RSpec.describe Admin::RegistrationJourneyTemplatesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:registration_journey) do
    RegistrationJourney.create!(name: "Demo journey", slug: "demo-journey")
  end

  before { sign_in_as_admin(super_admin: true) }

  describe "GET /admin/registration-journeys/:registration_journey_id/template/new" do
    it "shows the available registration templates" do
      registration_template = RegistrationTemplate.create!(
        name: "NPD funding eligibility",
        description: "Adds the initial NPD funding eligibility questions.",
        template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
      )

      get new_admin_registration_journey_template_path(registration_journey)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("NPD funding eligibility")
      expect(response.body).to include("Adds the initial NPD funding eligibility questions.")

      document = Nokogiri::HTML(response.body)
      apply_form = document.at_css(
        "form[action='#{admin_registration_journey_template_path(registration_journey)}'] " \
          "input[name='registration_template_id'][value='#{registration_template.id}']",
      )
      expect(apply_form).to be_present
    end
  end

  describe "POST /admin/registration-journeys/:registration_journey_id/template" do
    it "applies the selected template and redirects to the journey" do
      registration_template = RegistrationTemplate.create!(
        name: "NPD funding eligibility",
        template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
      )

      expect {
        post admin_registration_journey_template_path(registration_journey),
             params: { registration_template_id: registration_template.id }
      }.to change(registration_journey.registration_steps, :count).by(11)

      expect(response).to redirect_to(admin_registration_journey_path(registration_journey))
    end

    it "does not invoke a class outside the registered template services" do
      registration_template = RegistrationTemplate.create!(
        name: "Invalid template",
        template_generating_service_class: "Kernel",
      )

      expect {
        post admin_registration_journey_template_path(registration_journey),
             params: { registration_template_id: registration_template.id }
      }.not_to change(registration_journey.registration_steps, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
