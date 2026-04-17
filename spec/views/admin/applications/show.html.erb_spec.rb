require "rails_helper"

RSpec.describe "admin/applications/show.html.erb", type: :view do
  subject { Capybara.string(render) }

  let(:application_trait) { :accepted }
  let(:application_attributes) { {} }
  let :application do
    application = build_stubbed(:application, application_trait, **application_attributes)
    allow(application).to receive(:lead_provider).and_return(build_stubbed(:lead_provider))
    application
  end

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
  end

  describe "a summary card for a minimal application" do
    let(:application_attributes) { { institution: nil } }

    it { is_expected.to have_css "h1", text: "Application details" }
    it { is_expected.to have_summary_item "Application ID", application.ecf_id }
    it { is_expected.to have_summary_item "Provider", application.lead_provider.name }
    it { is_expected.to have_summary_item "Course", application.course.name }
    it { is_expected.to have_summary_item "Unique reference number (URN)", "" }
    it { is_expected.to have_summary_item "UK Provider Reference Number (UKPRN)", "" }
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
        expect(subject).to have_link("Defer/Withdraw")
        expect(subject).not_to have_link("Accept")
      end
    end

    context "when the application is withdrawn" do
      let(:application_trait) { :withdrawn }

      it do
        expect(subject).to have_link("Revert to Pending")
        expect(subject).to have_link("Accept")
        expect(subject).not_to have_link("Defer/Withdraw")
      end
    end
  end
end
