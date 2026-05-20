require "rails_helper"

RSpec.describe "Reception Registrations / Choose Your Course", type: :request do
  let(:user) { create(:user) }
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
    it "redirects to start" do
      get url
      expect(response).to redirect_to(reception_registration_path("start"))
    end
  end

  describe "PATCH /reception-registration/choose-your-course" do
    context "with valid course" do
      it "redirects to exit" do
        patch url, params: { "choose-your-course" => { course_identifier: course.identifier } }
        expect(response).to redirect_to(reception_registration_path("exit"))
      end
    end

    context "with invalid form" do
      it "redirects to exit" do
        patch url, params: { "choose-your-course" => { course_identifier: nil } }
        expect(response).to redirect_to(reception_registration_path("exit"))
      end
    end
  end
end
