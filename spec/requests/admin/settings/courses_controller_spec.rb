require "rails_helper"

RSpec.describe Admin::Settings::CoursesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course, name: "Send course") }
  let(:lead_provider) { create(:lead_provider, name: "Provider One") }
  let(:delivery_partner) { create(:delivery_partner, name: "Partner One") }

  before { sign_in_as_admin(super_admin: true) }

  describe "#show" do
    context "when the course has delivery partnerships" do
      before do
        create(:delivery_partnership, course:, lead_provider:, delivery_partner:)
        get admin_settings_course_path(course)
      end

      it { expect(response).to have_http_status(:success) }

      it "lists the delivery partners grouped by their lead provider" do
        expect(response.body).to include("Delivery partners")
        expect(response.body).to include("Provider One")
        expect(response.body).to include("Partner One")
      end
    end

    context "when the course has no delivery partnerships" do
      before { get admin_settings_course_path(course) }

      it "says there are no delivery partners" do
        expect(response.body).to include("No delivery partners.")
      end
    end
  end
end
