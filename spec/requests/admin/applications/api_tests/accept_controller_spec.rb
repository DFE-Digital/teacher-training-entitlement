# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::AcceptController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :pending, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_accept_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:accept_application) { instance_double(::APITests::AcceptApplication, call: api_response) }

    before do
      allow(::APITests::AcceptApplication).to receive(:new).with(application:, funded_place: "true").and_return(accept_application)

      post admin_applications_api_tests_accept_index_path(application), params: { form: { funded_place: true } }
    end

    it "calls the accept helper with the application and funded place" do
      expect(::APITests::AcceptApplication).to have_received(:new).with(application:, funded_place: "true")
      expect(accept_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
