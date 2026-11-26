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

    context "when the course has uplift institutions" do
      let(:institution) { create(:institution, name: "Uplift School") }

      before do
        create(:course_uplift_institution, course:, institution:)
        get admin_settings_course_path(course)
      end

      it "shows the uplift incentive as yes" do
        expect(uplift_incentive_value).to eq("Yes")
      end

      it "lists the uplift institutions in a details section" do
        details = Nokogiri::HTML(response.body).at_css("details#uplift-institutions")

        expect(details.at_css("summary").text).to include("Uplift institutions")
        expect(details.text).to include("Uplift School")
      end
    end

    context "when the course has no uplift institutions" do
      before { get admin_settings_course_path(course) }

      it "shows the uplift incentive as no" do
        expect(uplift_incentive_value).to eq("No")
      end

      it "has no uplift institutions details section" do
        expect(response.body).not_to include("Uplift institutions")
      end
    end
  end

  def uplift_incentive_value
    Nokogiri::HTML(response.body)
      .css(".govuk-summary-list__row")
      .find { |row| row.at_css(".govuk-summary-list__key").text.strip == "Uplift incentive" }
      .at_css(".govuk-summary-list__value")
      .text
      .strip
  end
end
