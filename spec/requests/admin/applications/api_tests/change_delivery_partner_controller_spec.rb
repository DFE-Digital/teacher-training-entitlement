# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::ChangeDeliveryPartnerController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :started, lead_provider:) }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: { application.cohort => lead_provider }) }
  let!(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { application.cohort => lead_provider }) }
  let(:declaration) { application.declarations.first }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_change_delivery_partner_index_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:change_delivery_partner) { instance_double(::APITests::ChangeDeliveryPartner, call: api_response) }

    before do
      allow(::APITests::ChangeDeliveryPartner).to receive(:new).with(
        declaration:,
        delivery_partner:,
        secondary_delivery_partner:,
      ).and_return(change_delivery_partner)

      post admin_applications_api_tests_change_delivery_partner_index_path(application), params: {
        form: {
          declaration_id: declaration.id,
          delivery_partner_id: delivery_partner.id,
          secondary_delivery_partner_id: secondary_delivery_partner.id,
        },
      }
    end

    it "calls the change delivery partner helper with the selected records" do
      expect(::APITests::ChangeDeliveryPartner).to have_received(:new).with(
        declaration:,
        delivery_partner:,
        secondary_delivery_partner:,
      )
      expect(change_delivery_partner).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
