require "rails_helper"

RSpec.describe Admin::Settings::Courses::ProvidersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:course) { create(:course, name: "Send course") }
  let(:lead_provider) { create(:lead_provider, name: "Provider One") }
  let(:course_url) { "https://provider.example.com" }
  let(:email) { "contact@provider.example.com" }

  before do
    create(:contract_year, :generic, course:, lead_provider:, course_url:, email:)
    create(:contract_year, course:, lead_provider:, academic_year: 2024, recruitment_target: 100, teacher_funding: 900)
  end

  describe "#show" do
    context "when logged in as super admin" do
      before { sign_in_as_admin(super_admin: true) }

      context "with delivery partnerships" do
        before do
          create(:delivery_partnership, course:, lead_provider:, delivery_partner: create(:delivery_partner, name: "Partner One"))
        end

        it "returns success and renders the lead provider contract details" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Provider One contract details")
          expect(response.body).to include("Send course")
        end

        it "shows the overview course url and email" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response.body).to include("Course url")
          expect(response.body).to include("https://provider.example.com")
          expect(response.body).to include("Email")
          expect(response.body).to include("contact@provider.example.com")
        end

        it "shows the academic year contract details with formatted funding" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response.body).to include("2024")
          expect(response.body).to include("100")
          expect(response.body).to include("£900.00")
        end

        it "lists the delivery partners" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response.body).to include("Partner One")
        end
      end

      context "with no delivery partnerships" do
        it "says there are no delivery partners" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response.body).to include("No delivery partners.")
        end
      end

      context "when the generic contract has blank course url and email" do
        let(:course_url) { nil }
        let(:email) { nil }

        it "shows the placeholder" do
          get admin_settings_course_provider_path(course, lead_provider)

          expect(response.body).to include("Course url")
          expect(response.body).to include("Email")
          expect(response.body).to include("-")
        end
      end
    end

    context "when logged in as normal admin" do
      before { sign_in_as_admin(super_admin: false) }

      it "redirects to the sign in page" do
        get admin_settings_course_provider_path(course, lead_provider)

        expect(response).to redirect_to(sign_in_path)
      end

      it "flashes the unauthorized alert" do
        get admin_settings_course_provider_path(course, lead_provider)

        expect(flash[:alert]).to eq({ title: "Unauthorized", message: "Sign in with your administrator account" })
      end
    end

    context "when the lead provider is not a provider of the course" do
      before { sign_in_as_admin(super_admin: true) }

      it "returns not found" do
        other_lead_provider = create(:lead_provider)

        get admin_settings_course_provider_path(course, other_lead_provider)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the course does not exist" do
      before { sign_in_as_admin(super_admin: true) }

      it "returns not found" do
        get admin_settings_course_provider_path(course_id: "nonexistent", id: lead_provider.id)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
