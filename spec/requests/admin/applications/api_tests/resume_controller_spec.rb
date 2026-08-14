# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::ResumeController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) { create(:course_cohort, lead_provider:) }
  let(:application) { create(:application, :deferred, course_cohort:, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_resume_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:resume_application) { instance_double(::APITests::ResumeApplication, call: api_response) }

    before do
      allow(::APITests::ResumeApplication).to receive(:new).with(application:, course_cohort:).and_return(resume_application)

      post admin_applications_api_tests_resume_index_path(application), params: { course_cohort_id: course_cohort.id }
    end

    it "calls the resume helper with the application and course cohort" do
      expect(::APITests::ResumeApplication).to have_received(:new).with(application:, course_cohort:)
      expect(resume_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
