require "rails_helper"

RSpec.describe "Applications::ApplicationsController", type: :request do
  let(:pending_application) { create(:application, :pending) }

  let(:teacher) { pending_application.teacher }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ teacher_id: teacher.id })
  end

  describe "GET /applications" do
    context "when the teacher has multiple applications" do
      let!(:completed_application) { create(:application, :completed, :for_cohort_starting_on, teacher: pending_application.teacher, registration_starts_at: Date.new(2021, 4, 1)) }

      it do
        get "/applications"

        expect(response).to redirect_to(application_path(completed_application.ecf_id))
      end
    end
  end

  describe "GET /applications/:ecf_id" do
    context "when the teacher does not own the application" do
      let(:teacher) { create(:teacher) }

      it "redirects to the root path" do
        get application_path(pending_application.ecf_id)

        expect(response).to redirect_to(applications_path)
      end
    end

    context "when the teacher visits a pending application" do
      it do
        get "/applications/#{pending_application.ecf_id}"

        expect(response).to be_successful
      end
    end

    context "when the teacher visits an application which doesn't exist" do
      it "redirects you back to aaa" do
        get "/applications/does-not-exist"

        expect(response).to redirect_to(applications_path)
      end
    end
  end
end
