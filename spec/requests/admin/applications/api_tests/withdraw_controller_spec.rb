# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::WithdrawController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :started) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_withdraw_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:withdraw_application) { instance_double(::APITests::WithdrawApplication, call: api_response) }

    before do
      allow(::APITests::WithdrawApplication).to receive(:new).with(application:).and_return(withdraw_application)

      post admin_applications_api_tests_withdraw_index_path(application)
    end

    it "calls the withdraw helper with the application" do
      expect(::APITests::WithdrawApplication).to have_received(:new).with(application:)
      expect(withdraw_application).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
