require "rails_helper"

RSpec.describe "Reception Registrations / Funding Your Course", type: :request do
  let(:user) { create(:user) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :tte_early_years, display: true, lead_provider:) }
  let(:school) { create(:school, urn: "123456") }
  let(:url) { "/reception-registration/funding-your-course" }
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

  describe "GET /reception-registration/funding-your-course" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_funding_your_course)
    end
  end

  describe "PATCH /reception-registration/funding-your-course" do
    context "with valid funding" do
      it "redirects to share provider path" do
        patch url, params: { "funding-your-course" => { funding: "self" } }
        expect(response).to redirect_to(reception_registration_path("share-provider"))
      end
    end

    context "with invalid form" do
      it "renders form again when funding is blank" do
        patch url, params: { "funding-your-course" => { funding: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_funding_your_course)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:funding]).to eq(["can't be blank"])
      end

      it "renders form again when funding is not an option" do
        patch url, params: { "funding-your-course" => { funding: "not-an-option" } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_funding_your_course)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:funding]).to eq(["is not included in the list"])
      end
    end
  end
end
