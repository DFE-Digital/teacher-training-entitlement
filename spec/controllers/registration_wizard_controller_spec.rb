require "rails_helper"

RSpec.describe RegistrationWizardController do
  let(:missing_institution_wizard) do
    Class.new do
      def initialize(*args); end
      def respond_to_missing?(*) = true
      def method_missing(*) = raise FundingEligibility::MissingMandatoryInstitution
    end
  end

  let(:current_user) { create(:user) }

  before { session["user_id"] = current_user.id }

  subject(:page_response) { make_request && response }

  RSpec.shared_examples "it redirects on missing mandatory institution" do
    before do
      allow(RegistrationWizard).to receive(:new).and_return(missing_institution_wizard.new)
      make_request
    end

    it { is_expected.to redirect_to registration_wizard_show_path("work-setting") }
  end

  describe "#show" do
    let(:make_request) { get(:show, params: { step: "course-start-date" }) }

    it_behaves_like "it redirects on missing mandatory institution"

    it { is_expected.to have_http_status :success }
    it { expect(page_response.headers).to include "cache-control" => "no-store" }

    context "when application already submitted for course" do
      let(:lead_provider) { create(:lead_provider) }
      let(:course) { create(:course, :tte_early_years, lead_provider:) }
      let!(:application) { create(:application, :accepted, course:, user: current_user) }

      before do
        patch(:update, params: { step: "choose-your-provider", registration_wizard: { lead_provider_id: lead_provider.id } })
      end

      it "redirects to account/registration page with alert" do
        expect(response).to redirect_to application_path(application.ecf_id)
        expect(flash[:alert]).to eq({ title: "Application already registered", message: "You have already made an application for #{course.name}" })
      end
    end

    context "when user has a withdrawn application for the course" do
      let(:lead_provider) { create(:lead_provider) }
      let(:course) { create(:course, :tte_early_years, lead_provider:) }
      let!(:application) { create(:application, :withdrawn, course:, user: current_user) }

      before do
        patch(:update, params: { step: "choose-your-provider", registration_wizard: { lead_provider_id: lead_provider.id } })
      end

      it "does not redirect to the withdrawn application" do
        expect(response).not_to redirect_to application_path(application.ecf_id)
      end
    end
  end

  describe "#update" do
    let(:wizard_params) { { course_start_date: "yes" } }
    let(:make_request) { patch :update, params: { step: "course-start-date", registration_wizard: wizard_params } }

    it_behaves_like "it redirects on missing mandatory institution"

    it "persists data to session" do
      make_request
      expect(session["registration_store"]["course_start_date"]).to eql("yes")
    end

    context "when step is being skipped" do
      before do
        allow(RegistrationWizard).to receive(:new).and_return(wizard)
        allow(wizard).to receive(:save!).and_call_original
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:skip_step?).and_return(true)

        make_request
      end

      let :wizard do
        RegistrationWizard.new(current_step: "course_start_date",
                               store: {},
                               params: wizard_params,
                               request:,
                               current_user:)
      end

      it "redirects to course-start-date page" do
        expect(response).to redirect_to registration_wizard_show_path("choose-your-provider")
        expect(wizard).not_to have_received(:save!)
      end
    end

    context "when form requirements are not met" do
      before do
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:requirements_met?).and_return(false)

        make_request
      end

      it "redirects to home page" do
        expect(response).to redirect_to root_path
      end
    end
  end
end
