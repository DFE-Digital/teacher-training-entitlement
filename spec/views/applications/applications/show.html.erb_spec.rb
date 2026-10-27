require "rails_helper"

RSpec.describe "applications/applications/show.html.erb", type: :view do
  let(:application) { build_stubbed(:application) }
  let(:lead_provider) { build_stubbed(:lead_provider) }

  subject { Capybara.string(render) }

  before do
    current_application = application
    view.define_singleton_method(:application) { current_application }
    allow(application).to receive(:lead_provider).and_return(lead_provider)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
  end

  context "when application is pending" do
    let(:application) { build_stubbed(:application, :pending) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_start_index_path(application.ecf_id) }
  end

  context "when application is accepted" do
    let(:application) { build_stubbed(:application, :accepted) }

    it { is_expected.to have_link "Register with a different provider", href: application_change_provider_contact_us_path(application.ecf_id) }
  end

  context "when application is started" do
    let(:application) { build_stubbed(:application, :started) }

    it { is_expected.not_to have_link "Register with a different provider" }
  end

  describe "work details" do
    subject(:work_details) { Capybara.string(render).find(".govuk-summary-card", text: "Work details") }

    context "when the workplace is in England" do
      let(:application) { build_stubbed(:application, teacher_catchment: Institution::ENGLAND_SUBDIVISION_CODE) }

      it { is_expected.to have_summary_item "Workplace in England", "Yes" }
    end

    context "when the workplace is not in England" do
      let(:application) { build_stubbed(:application, teacher_catchment: "another") }

      it { is_expected.to have_summary_item "Workplace in England", "No" }
    end

    context "without an institution" do
      let(:application) { build_stubbed(:application, institution: nil) }

      it "does not show the workplace row" do
        expect(work_details).to have_no_css(".govuk-summary-list__key", text: "Workplace", exact_text: true)
      end
    end
  end
end
