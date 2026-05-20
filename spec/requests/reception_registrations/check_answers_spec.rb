require "rails_helper"

RSpec.describe "Reception Registrations / Check Answers", type: :request do
  let(:user) { create(:user, :with_verified_trn) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :tte_early_years, display: true, lead_provider:) }
  let(:school) { create(:school, urn: "123456") }
  let(:url) { "/reception-registration/check-answers" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
      teacher_catchment: "england",
      work_setting: "other",
      institution_id: school.institution.id.to_s,
      funding: "self",
      can_share_choices: "1",
      eligible_for_funding: false,
      funding_eligibility_status_code: "ineligible_setting",
      trn: user.trn,
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    school

    allow(Emails::SendApplicationSubmissionEmailJob).to receive(:perform_later)
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/check-answers" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_check_answers)
    end
  end

  describe "PATCH /reception-registration/check-answers" do
    it "creates an application and redirects to exit" do
      expect { patch url }.to change(Application, :count).by(1)

      created_application = user.applications.order(:created_at).last
      expect(created_application).to have_attributes(
        course:,
        lead_provider:,
        institution: school.institution,
        eligible_for_funding: false,
        funding_eligiblity_status_code: "ineligible_setting",
        funding_choice: "self",
        teacher_catchment: "england",
        work_setting: "other",
        status: Application::PENDING,
      )
      expect(created_application.raw_application_data).to include(
        "course_identifier" => course.identifier,
        "lead_provider_id" => lead_provider.id.to_s,
        "funding" => "self",
      )
      expect(Emails::SendApplicationSubmissionEmailJob).to have_received(:perform_later).with(application: created_application)
      expect(response).to redirect_to(application_path(created_application.ecf_id))
    end
  end
end
