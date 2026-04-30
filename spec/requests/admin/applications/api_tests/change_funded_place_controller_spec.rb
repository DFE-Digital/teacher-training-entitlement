# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::ChangeFundedPlaceController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :accepted, lead_provider:) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_change_funded_place_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:change_funded_place) { instance_double(::APITests::ChangeFundedPlace, call: api_response) }

    before do
      allow(::APITests::ChangeFundedPlace).to receive(:new).with(application:, funded_place: "false").and_return(change_funded_place)

      post admin_applications_api_tests_change_funded_place_index_path(application), params: { form: { funded_place: false } }
    end

    it "calls the change funded place helper with the application and funded place" do
      expect(::APITests::ChangeFundedPlace).to have_received(:new).with(application:, funded_place: "false")
      expect(change_funded_place).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
