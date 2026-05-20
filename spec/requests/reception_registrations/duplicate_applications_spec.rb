require "rails_helper"

RSpec.describe "Reception Registrations / Duplicate Applications", type: :request do
  let(:user) { create(:user) }
  let(:course) { Course.reception || create(:course, :tte_early_years) }
  let!(:application) { create(:application, :pending, user:, course:, cohort: Cohort.current) }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /reception-registration/start" do
    it "redirects to an existing active application for the reception course" do
      get reception_registration_path("start")

      expect(response).to redirect_to(application_path(application.ecf_id))
      expect(flash[:alert]).to eq(
        title: "Application already registered",
        message: "You have already made an application for #{course.name}",
      )
    end
  end
end
