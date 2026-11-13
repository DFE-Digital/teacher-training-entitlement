require "rails_helper"

RSpec.describe Admin::Settings::CoursesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course, name: "Send course") }
  let(:lead_provider) { create(:lead_provider, name: "Provider One") }

  before { sign_in_as_admin(super_admin: true) }

  describe "#show" do
    context "when the course has lead providers" do
      before do
        create(:contract_year, :generic, course:, lead_provider:)
        get admin_settings_course_path(course)
      end

      it { expect(response).to have_http_status(:success) }

      it "lists the lead providers" do
        expect(response.body).to include("Provider One")
      end

      it "includes a view details link to the provider page" do
        expect(response.body).to include("View details")
        expect(response.body).to include(admin_settings_course_provider_path(course, lead_provider))
      end
    end

    context "when the course has no lead providers" do
      before { get admin_settings_course_path(course) }

      it { expect(response).to have_http_status(:success) }

      it "has no view details links" do
        expect(response.body).not_to include("View details")
      end
    end
  end
end
