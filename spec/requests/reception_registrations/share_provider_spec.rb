require "rails_helper"

RSpec.describe "Reception Registrations / Share Provider", type: :request do
  let(:user) { create(:user) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { create(:course, :tte_early_years, display: true, lead_provider:) }
  let(:school) { create(:school, urn: "123456") }
  let(:url) { "/reception-registration/share-provider" }
  let(:registration_session) do
    {
      confirmation: "yes",
      course_identifier: course.identifier,
      lead_provider_id: lead_provider.id.to_s,
      teacher_catchment: "england",
      work_setting: "other",
      institution_id: school.institution.id.to_s,
      funding: "self",
    }
  end
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    school

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/share-provider" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_share_provider)
    end
  end

  describe "PATCH /reception-registration/share-provider" do
    context "with accepted sharing consent" do
      it "redirects to check answers path" do
        patch url, params: { "share-provider" => { can_share_choices: "1" } }
        expect(response).to redirect_to(reception_registration_path("check-answers"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "share-provider" => { can_share_choices: "0" } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_share_provider)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:can_share_choices]).to eq(["must be accepted"])
      end
    end
  end
end
