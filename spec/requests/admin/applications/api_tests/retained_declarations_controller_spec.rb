# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::RetainedDeclarationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :started, lead_provider:) }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: { application.cohort => lead_provider }) }
  let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
  let(:retained_declaration) { instance_double(::APITests::RetainedDeclaration, call: api_response) }

  before { sign_in_as_admin(super_admin: true) }

  shared_examples "a retained declaration API test" do
    describe "#index" do
      before { get path }

      it { is_expected.to have_http_status :success }
    end

    describe "#create" do
      before do
        allow(::APITests::RetainedDeclaration).to receive(:new).with(
          application:,
          declaration_type:,
          delivery_partner:,
        ).and_return(retained_declaration)

        post path, params: { form: { delivery_partner_id: delivery_partner.id } }
      end

      it "calls the retained declaration helper with the selected delivery partner" do
        expect(::APITests::RetainedDeclaration).to have_received(:new).with(
          application:,
          declaration_type:,
          delivery_partner:,
        )
        expect(retained_declaration).to have_received(:call)

        expect(subject).to be_successful
      end
    end
  end

  context "with the retained-1 endpoint" do
    let(:declaration_type) { Milestone::RETAINED_1 }
    let(:path) { admin_applications_api_tests_retained_1_declarations_path(application) }

    it_behaves_like "a retained declaration API test"
  end

  context "with the retained-2 endpoint" do
    let(:declaration_type) { Milestone::RETAINED_2 }
    let(:path) { admin_applications_api_tests_retained_2_declarations_path(application) }

    it_behaves_like "a retained declaration API test"
  end
end
