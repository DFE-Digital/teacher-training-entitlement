require "rails_helper"

RSpec.describe "Reception Registrations / Ineligible For Funding", type: :request do
  let(:user) { create(:user) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :tte_early_years, display: true, lead_provider:) }
  let(:school) { create(:school, urn: "123456") }
  let(:url) { "/reception-registration/ineligible-for-funding" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
      teacher_catchment: "england",
      work_setting: "other",
      institution_id: school.institution.id.to_s,
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    school

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/ineligible-for-funding" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_ineligible_for_funding)
    end

    it "renders a continue link to funding your course" do
      get url
      expect(response.body).to include("Continue")
      expect(response.body).to include(reception_registration_path("funding-your-course"))
    end
  end
end
