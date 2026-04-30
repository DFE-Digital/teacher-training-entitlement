# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :accepted, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "data" => [] }) }
    let(:list_applications) { instance_double(::APITests::ListApplications, call: api_response) }

    before do
      allow(::APITests::ListApplications).to receive(:new).with(lead_provider: application.lead_provider, filters: ActionController::Parameters.new(status: "pending").permit(:status)).and_return(list_applications)

      get admin_applications_api_tests_applications_path(application), params: { form: { status: "pending" } }
    end

    it "calls the list applications helper with the provider and filters" do
      expect(::APITests::ListApplications).to have_received(:new).with(
        lead_provider: application.lead_provider,
        filters: ActionController::Parameters.new(status: "pending").permit(:status),
      )
      expect(list_applications).to have_received(:call)

      expect(subject).to be_successful
    end
  end

  describe "#show" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "data" => {} }) }
    let(:show_application) { instance_double(::APITests::ShowApplication, call: api_response) }

    before do
      allow(::APITests::ShowApplication).to receive(:new).with(application:).and_return(show_application)

      get admin_applications_api_tests_application_path(application, application.ecf_id)
    end

    it "calls the show application helper with the application" do
      expect(::APITests::ShowApplication).to have_received(:new).with(application:)
      expect(show_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
