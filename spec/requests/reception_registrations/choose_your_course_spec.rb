require "rails_helper"

RSpec.describe "Reception Registrations / Choose Your Course", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:course) { create(:course, :tte_early_years, display: true) }
  let(:url) { "/reception-registration/choose-your-course" }
  let(:registration_session) { { confirmation: "yes" } }
  let(:session) { { user_id: user.id, "registrations_#{user.id}" => registration_session }.with_indifferent_access }

  before do
    course

    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  describe "GET /reception-registration/choose-your-course" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_choose_your_course)
    end
  end

  describe "PATCH /reception-registration/choose-your-course" do
    context "with valid course" do
      it "redirects to choose provider path" do
        patch url, params: { "choose-your-course" => { course_identifier: course.identifier } }
        expect(response).to redirect_to(reception_registration_path("choose-your-provider"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { "choose-your-course" => { course_identifier: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_choose_your_course)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:course_identifier]).to eq(["can't be blank"])
      end
    end
  end
end
