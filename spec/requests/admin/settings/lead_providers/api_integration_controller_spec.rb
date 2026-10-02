require "rails_helper"

RSpec.describe Admin::Settings::LeadProviders::APIIntegrationController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Rails).to receive(:env).and_return(environment.inquiry)
    sign_in_as_admin(super_admin: true)
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:environment) { "sandbox" }

  describe "create test data" do
    subject(:request) do
      post test_data_admin_settings_lead_provider_path(lead_provider)
    end

    let(:service) { instance_double(ValidTestDataGenerators::APITestScenariosSeeder, call: outcome) }

    before do
      allow(ValidTestDataGenerators::APITestScenariosSeeder).to receive(:new).with(lead_provider:).and_return(service)
    end

    context "when successful" do
      let(:outcome) { instance_double(ValidTestDataGenerators::APITestScenariosSeeder::Outcome, success: true, applications_count: 2) }

      it do
        request
        expect(flash[:success]).to eq("API test scenarios seeded successfully for #{lead_provider.name}. Created #{outcome.applications_count} applications.")
        expect(response).to redirect_to admin_settings_lead_provider_path(lead_provider)
      end
    end

    context "when fails" do
      let(:outcome) { instance_double(ValidTestDataGenerators::APITestScenariosSeeder::Outcome, success: false) }

      it do
        request
        expect(flash[:error]).to eq("Failed to seed data")
        expect(response).to redirect_to admin_settings_lead_provider_path(lead_provider)
      end
    end
  end
end
