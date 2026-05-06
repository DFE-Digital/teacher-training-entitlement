# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::APITests::VoidDeclarationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, :started, lead_provider:) }
  let(:declaration) { application.declarations.first }

  before { sign_in_as_admin(super_admin: true) }

  describe "#index" do
    before { get admin_applications_api_tests_void_declarations_path(application) }

    it { is_expected.to have_http_status :success }
  end

  describe "#create" do
    let(:api_response) { instance_double(HTTParty::Response, code: 200, parsed_response: { "message" => "ok" }) }
    let(:void_declaration) { instance_double(::APITests::VoidDeclaration, call: api_response) }

    before do
      allow(::APITests::VoidDeclaration).to receive(:new).with(declaration:).and_return(void_declaration)

      post admin_applications_api_tests_void_declarations_path(application), params: {
        form: { declaration_id: declaration.id },
      }
    end

    it "calls the void declaration helper with the declaration" do
      expect(::APITests::VoidDeclaration).to have_received(:new).with(declaration:)
      expect(void_declaration).to have_received(:call)

      expect(subject).to be_successful
    end
  end
end
