require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  before do
    create(:course_cohort)
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ "user_id" => user.id })
  end

  describe "GET /registrations/course-selection/start" do
    it "renders the start step from the course-selection wizard" do
      get "/registrations/course-selection/start"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Professional development for teachers")
    end
  end

  describe "PATCH /registrations/course-selection/start" do
    it "saves the start answer and moves to course selection" do
      patch "/registrations/course-selection/start", params: { start: { self_funded: "true" } }

      expect(response).to redirect_to("/registrations/course-selection/courses")
    end
  end
end
