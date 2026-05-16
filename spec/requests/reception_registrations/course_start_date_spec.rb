require "rails_helper"

RSpec.describe "Reception Registrations / Course Start Date", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:url) { "/reception-registration/course-start-date" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /reception-registration/course-start-date" do
    it "renders the show template" do
      get url
      expect(response).to render_template(:show)
      expect(response).to render_template(:_course_start_date)
    end
  end

  describe "PATCH /reception-registration/course-start-date" do
    context "with valid confirmation" do
      it "redirects to choose course path" do
        patch url, params: { "course-start-date" => { confirmation: "yes" } }
        expect(response).to redirect_to(reception_registration_path("choose-your-course"))
      end
    end

    context "without confirmation" do
      it "redirects to the start" do
        patch url, params: { "course-start-date" => { confirmation: "no" } }
        expect(response).to redirect_to(reception_registration_path("cannot-register-yet"))
      end
    end

    context "with invalid form" do
      it "renders form again" do
        patch url, params: { start: { confirmation: nil } }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to render_template(:_course_start_date)
        expect(assigns[:step]).not_to be_nil
        expect(assigns[:step].errors[:confirmation]).to eq(["can't be blank"])
      end
    end
  end
end
