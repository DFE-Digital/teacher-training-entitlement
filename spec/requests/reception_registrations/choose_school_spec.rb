require "rails_helper"

RSpec.describe "Reception Registrations / Choose School", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, display: true, lead_provider:) }
  let(:school) { create(:school, urn: "123456") }
  let(:url) { "/reception-registration/choose-school" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
      teacher_catchment: "england",
      work_setting: "a_school",
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    school

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/choose-school" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_choose_school)
    end
  end

  describe "PATCH /reception-registration/choose-school" do
    context "with valid school" do
      it "redirects to possible funding path" do
        patch url, params: { "choose-school" => { institution_id: school.institution.id } }
        expect(response).to redirect_to(reception_registration_path("possible-funding"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "choose-school" => { institution_name: "a" * 65 } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_school)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:institution_name]).to eq(["is too long (maximum is 64 characters)"])
      end
    end
  end
end
