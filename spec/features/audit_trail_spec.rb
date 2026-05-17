require "rails_helper"

RSpec.feature "Recording audit trail via papertrail", :revisit, :versioning, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:cohort) { create(:cohort, :current, :without_funding_cap) }

  describe "an admin making changes" do
    subject(:change_author) { application.versions.last.whodunnit }

    before do
      sign_in_as_admin

      post admin_applications_change_status_path(application, params:)
    end

    let :application do
      create(:application, :accepted, cohort:).tap do |application|
        create(:declaration, application:)
      end
    end

    let :params do
      {
        form: {
          status: :withdrawn,
          reason: Admin::Applications::ChangeStatusForm::REASON_OPTIONS["withdrawn"].first,
        },
      }
    end

    let(:version) { application.versions.last }

    it "records the admin details" do
      expect(change_author).to eq "AdminUser #{AdminUser.maximum(:id)}"
    end
  end

  describe "a lead provider making changes" do
    subject(:change_author) { application.reload.versions.last.whodunnit }

    before do
      travel_to Date.parse("2024-12-13") # ensure schedule identifier is predicable

      APIToken.create_with_known_token!(raw_token, lead_provider:)
      create(:schedule, :tte_reception_autumn,
             course_group: application.course.course_group,
             cohort: application.cohort)

      post accept_api_v1_application_path(application.ecf_id), headers:
    end

    let(:raw_token) { "a-token" }
    let(:course) { create(:course, :tte_early_years) }
    let(:lead_provider) { create :lead_provider }
    let(:application) { create :application, lead_provider:, course:, cohort: }

    let :headers do
      {
        "Content-Type" => "application/json",
        "Authorization" =>
          ActionController::HttpAuthentication::Token.encode_credentials(raw_token),
      }
    end

    it "records the lead providers details" do
      expect(change_author).to eq "Lead provider #{lead_provider.id}"
    end
  end

  describe "a public user making changes" do
    subject(:change_author) { Application.last.versions.last.whodunnit }

    before do
      create(:cohort, :current)
      school

      allow(Emails::SendApplicationSubmissionEmailJob).to receive(:perform_later)
      allow_any_instance_of(ApplicationController)
        .to receive(:session).and_return({
          "registrations_#{current_user.id}" => registration_state,
          :user_id => current_user.id,
        })

      patch reception_registration_path("check-answers")
    end

    let(:current_user) { create(:user) }
    let(:lead_provider) { create(:lead_provider) }
    let(:course) { create(:course, :tte_early_years, lead_provider:, display: true) }
    let(:school) { create(:school) }
    let(:registration_state) do
      {
        confirmation: "yes",
        course_identifier: course.identifier,
        lead_provider_id: lead_provider.id.to_s,
        teacher_catchment: "england",
        work_setting: "other",
        works_in_school: false,
        works_in_childcare: false,
        institution_id: school.institution.id.to_s,
        funding: "self",
        can_share_choices: "1",
        eligible_for_funding: false,
        funding_eligibility_status_code: "ineligible_setting",
        trn: current_user.trn,
      }
    end

    it "records the lead providers details" do
      expect(change_author).to eq "Public User #{current_user.id}"
    end
  end
end
