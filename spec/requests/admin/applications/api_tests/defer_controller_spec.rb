# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::DeferController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :started, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_defer_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:defer_application) { instance_double(::APITests::DeferApplication, call: api_response) }

    before do
      allow(::APITests::DeferApplication).to receive(:new).with(application:).and_return(defer_application)

      post admin_applications_api_tests_defer_index_path(application)
    end

    it "calls the defer helper with the application" do
      expect(::APITests::DeferApplication).to have_received(:new).with(application:)
      expect(defer_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
