require "rails_helper"

RSpec.describe "admin/applications/show.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:application_trait) { :accepted }
  let(:application_attributes) { {} }
  let :application do
    application = build_stubbed(:application, application_trait, **application_attributes)
    allow(application).to receive_messages(
      lead_provider: build_stubbed(:lead_provider),
      application_lead_providers: application_lead_providers,
    )
    application
  end

  let(:application_lead_providers) { double(previous: previous_application_lead_providers) }
  let(:previous_application_lead_providers) { [] }
  let(:declarations) { [] }

  before do
    assign(:application, application)
    assign(:declarations, declarations)
  end

  describe "a summary card for a full application" do
    let :declarations do
      [
        build_stubbed(:declaration, application: application,
                                    lead_provider: application.lead_provider,
                                    declaration_type: "started",
                                    delivery_partner: nil),
        build_stubbed(:declaration, application: application,
                                    lead_provider: application.lead_provider,
                                    declaration_type: "retained-1"),
      ]
    end

    it { is_expected.to have_css(".govuk-caption-m", text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}", normalize_ws: true) }
    it { is_expected.to have_css "h1", text: "Application details" }

    context "with application overview summary card" do
      subject { Capybara.string(render).find(".govuk-summary-card", text: "Overview") }

      it { is_expected.to have_summary_item "Name", application.user.full_name }
      it { is_expected.to have_summary_item "Application ID", application.ecf_id }
      it { is_expected.to have_summary_item "User ID", application.user.ecf_id }
      it { is_expected.to have_summary_item "Provider", application.lead_provider.name }
      it { is_expected.to have_summary_item "Course", application.course.name }
    end

    context "when application has previous providers" do
      subject { Capybara.string(render).find(".govuk-summary-card", text: "Previous providers") }

      let(:previous_application_lead_providers) do
        [
          build_stubbed(
            :application_lead_provider,
            lead_provider: build_stubbed(:lead_provider, name: "First previous provider"),
            updated_at: Time.zone.local(2025, 5, 3),
            current: false,
          ),
          build_stubbed(
            :application_lead_provider,
            lead_provider: build_stubbed(:lead_provider, name: "Second previous provider"),
            updated_at: Time.zone.local(2025, 6, 4),
            current: false,
          ),
        ]
      end

      it { is_expected.to have_summary_item "First previous provider", "unassigned on 3 May 2025" }
      it { is_expected.to have_summary_item "Second previous provider", "unassigned on 4 June 2025" }
    end
  end

  describe "funding eligibility summary card" do
    subject(:summary_card) { Capybara.string(render).find(".govuk-summary-card", text: "Funding eligibility") }

    context "with a funding eligibility status code" do
      let(:application_attributes) { { funding_eligiblity_status_code: "previously_funded" } }

      it { is_expected.to have_summary_item "Status code", "Previously Funded" }
    end

    context "without a funding eligibility status code" do
      let(:application_attributes) { { funding_eligiblity_status_code: nil } }

      it { is_expected.to have_summary_item "Status code", "-" }
    end

    context "with funding choice data from the registration journey" do
      let(:application_attributes) { { raw_application_data: { "funding" => "school" } } }

      it { is_expected.to have_summary_item "Funding choice", "My workplace is covering the cost" }
    end

    context "without funding choice data from the registration journey" do
      let(:application_attributes) { { raw_application_data: {} } }

      it "does not show the funding choice row" do
        expect(summary_card).to have_no_css(".govuk-summary-list__key", text: "Funding choice", exact_text: true)
      end
    end
  end

  describe "workplace summary card" do
    subject(:summary_card) { Capybara.string(render).find(".govuk-summary-card", text: "Workplace") }

    context "with a work setting" do
      let(:application_attributes) { { work_setting: "state_funded_institution" } }

      it { is_expected.to have_summary_item "Setting", "State-funded nursery, pre-school, school or academy trust" }
    end

    context "without a work setting" do
      let(:application_attributes) { { work_setting: nil } }

      it "does not show the setting row" do
        expect(summary_card).to have_no_css(".govuk-summary-list__key", text: "Setting", exact_text: true)
      end
    end

    context "with an institution" do
      it { is_expected.to have_summary_item "Name", application.institution.name }
      it { is_expected.to have_summary_item "Unique reference number (URN)", application.institution.urn }
      it { is_expected.to have_summary_item "UK Provider Reference Number (UKPRN)", "" }
    end

    context "without an institution" do
      let(:application_attributes) { { institution: nil } }

      it "does not show institution rows" do
        expect(summary_card).to have_no_css(".govuk-summary-list__key", text: "Name", exact_text: true)
        expect(summary_card).to have_no_css(".govuk-summary-list__key", text: "Unique reference number (URN)", exact_text: true)
        expect(summary_card).to have_no_css(".govuk-summary-list__key", text: "UK Provider Reference Number (UKPRN)", exact_text: true)
      end
    end
  end

  describe "a summary card for a minimal application" do
    it { is_expected.to have_css "h1", text: "Application details" }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "Provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course", application.course.name }
    it { is_expected.to have_summary_item "Schedule identifier", "-" }
  end

  describe "Links for actions" do
    context "when the application is pending" do
      let(:application_trait) { :pending }

      it do
        expect(subject).not_to have_link("Revert to Pending")
        expect(subject).not_to have_link("Defer/Withdraw")
        expect(subject).not_to have_link("Accept")
      end
    end

    context "when the application is accepted" do
      let(:application_trait) { :accepted }

      it do
        expect(subject).to have_link("Revert to Pending")
        expect(subject).to have_link("Defer")
        expect(subject).not_to have_link("Accept")
      end
    end

    context "when the application is withdrawn" do
      let(:application_trait) { :withdrawn }

      it do
        expect(subject).not_to have_link("Revert to Pending")
        expect(subject).to have_link("Accept")
        expect(subject).not_to have_link("Defer/Withdraw")
      end
    end

    context "when the application is rejected" do
      let(:application_trait) { :rejected }

      it do
        expect(subject).to have_link("Revert to Pending")
      end
    end
  end
end
