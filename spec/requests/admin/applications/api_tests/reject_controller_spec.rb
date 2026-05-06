# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::RejectController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :pending, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_reject_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:reject_application) { instance_double(::APITests::RejectApplication, call: api_response) }

    before do
      allow(::APITests::RejectApplication).to receive(:new).with(application:).and_return(reject_application)

      post admin_applications_api_tests_reject_index_path(application)
    end

    it "calls the reject helper with the application" do
      expect(::APITests::RejectApplication).to have_received(:new).with(application:)
      expect(reject_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
