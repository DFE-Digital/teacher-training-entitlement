require "rails_helper"

RSpec.describe Admin::APITestScenariosController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before do
    allow(Rails).to receive(:env).and_return(environment.inquiry)
    sign_in_as_admin(super_admin: true)
  end

  let(:environment) { "sandbox" }

  describe "/admin/api-test-scenarios" do
    subject do
      get admin_api_test_scenarios_path
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end

  describe "create test scenario data" do
    let(:lead_provider) { create(:lead_provider) }

    subject do
      post admin_api_test_scenarios_path, params: { lead_provider_id: lead_provider.id }
      response
    end

    it { is_expected.to redirect_to admin_api_test_scenarios_path }
  end

  describe "create custom data" do
    let(:lead_provider) { create(:lead_provider) }

    subject do
      post create_custom_data_admin_api_test_scenarios_path, params: { lead_provider_id: lead_provider.id }
      response
    end

    it { is_expected.to redirect_to admin_api_test_scenarios_path }
  end
end
