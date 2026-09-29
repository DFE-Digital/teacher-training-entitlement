# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::RevertToPendingController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :accepted, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_revert_to_pending_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:revert_to_pending_application) { instance_double(::APITests::RevertToPendingApplication, call: api_response) }

    before do
      allow(::APITests::RevertToPendingApplication).to receive(:new).with(application:).and_return(revert_to_pending_application)

      post admin_applications_api_tests_revert_to_pending_index_path(application)
    end

    it "calls the revert to pending helper with the application" do
      expect(::APITests::RevertToPendingApplication).to have_received(:new).with(application:)
      expect(revert_to_pending_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
