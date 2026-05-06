# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::CompletedDeclarationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :started, lead_provider:) }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: { application.cohort => lead_provider }) }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_completed_declarations_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:completed_declaration) { instance_double(::APITests::CompletedDeclaration, call: api_response) }

    before do
      allow(::APITests::CompletedDeclaration).to receive(:new).with(
        application:,
        delivery_partner:,
        has_passed: nil,
      ).and_return(completed_declaration)

      post admin_applications_api_tests_completed_declarations_path(application), params: {
        form: { delivery_partner_id: delivery_partner.id },
      }
    end

    it "calls the completed declaration helper with the selected delivery partner" do
      expect(::APITests::CompletedDeclaration).to have_received(:new).with(
        application:,
        delivery_partner:,
        has_passed: nil,
      )
      expect(completed_declaration).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
