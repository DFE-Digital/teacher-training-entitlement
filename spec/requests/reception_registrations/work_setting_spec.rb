require "rails_helper"

RSpec.describe "Reception Registrations / Work Setting", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, display: true, lead_provider:) }
  let(:url) { "/reception-registration/work-setting" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
      teacher_catchment: "england",
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/work-setting" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_work_setting)
    end
  end

  describe "PATCH /reception-registration/work-setting" do
    context "with valid work setting" do
      it "redirects to choose school path" do
        patch url, params: { "work-setting" => { work_setting: "a_school" } }
        expect(response).to redirect_to(reception_registration_path("choose-school"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "work-setting" => { work_setting: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_work_setting)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:work_setting]).to eq(["can't be blank"])
      end
    end
  end
end
