require "rails_helper"

RSpec.describe "Reception Registrations / Teacher Catchment", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, display: true, lead_provider:) }
  let(:url) { "/reception-registration/teacher-catchment" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/teacher-catchment" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_teacher_catchment)
    end
  end

  describe "PATCH /reception-registration/teacher-catchment" do
    context "with valid teacher catchment" do
      it "redirects to work setting path" do
        patch url, params: { "teacher-catchment" => { teacher_catchment: "england" } }
        expect(response).to redirect_to(reception_registration_path("work-setting"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "teacher-catchment" => { teacher_catchment: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_teacher_catchment)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:teacher_catchment]).to eq(["can't be blank"])
      end
    end
  end
end
