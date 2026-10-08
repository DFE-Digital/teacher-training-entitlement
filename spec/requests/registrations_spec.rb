require "rails_helper"

RSpec.describe "Applications::ApplicationsController", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "User wants to create an application for a subsequent course_cohort" do
    [
      Application::REJECTED,
      Application::COMPLETED,
      Application::WITHDRAWN,
    ].each do |status|
      context "when previous application is reject" do
        before { create(:application, status.to_sym, user:) }

        it do
          get registration_wizard_show_path("course-start-date")
          expect(response.body).to include("Course start")
        end
      end
    end

    [
      Application::PENDING,
      Application::ACCEPTED,
      Application::STARTED,
      Application::DEFERRED,
    ].each do |status|
      context "when previous application is #{status}" do
        before { create(:application, status.to_sym, user:) }

        it do
          get registration_wizard_show_path("course-start-date")
          follow_redirect!
          expect(response.body).to include("Application already registered")
        end
      end
    end
  end
end
