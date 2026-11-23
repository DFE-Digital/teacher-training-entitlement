require "rails_helper"

RSpec.describe Admin::GuidanceController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe("GET /admin/guidances") do
    subject { get(admin_guidance_index_path) && response }

    context "when signed in as a super admin" do
      before { sign_in_as_admin(super_admin: true) }

      it "returns a 200 OK response" do
        expect(subject).to(have_http_status(:ok))
      end

      it "links to the courses management guidance" do
        expect(subject.body).to include(admin_guidance_path("courses-management"))
        expect(subject.body).not_to include(admin_guidance_path("settings-courses"))
      end
    end

    context "when signed in as an admin" do
      before { sign_in_as_admin }

      it "returns a 200 OK response" do
        expect(subject).to(have_http_status(:ok))
      end

      it "has sub navigation" do
        expect(subject.body).to include("Categories")
      end
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(subject).to redirect_to(sign_in_path)
      end
    end
  end

  describe("GET /admin/guidance/courses-management") do
    subject { get(admin_guidance_path("courses-management")) && response }

    context "when signed in as an admin" do
      before { sign_in_as_admin }

      it "explains editing delivery partners" do
        expect(subject).to(have_http_status(:ok))
        expect(subject.body).to include("At least one delivery partner must stay")
        expect(subject.body).to include("Select at least one delivery partner")
      end
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(subject).to redirect_to(sign_in_path)
      end
    end
  end
end
