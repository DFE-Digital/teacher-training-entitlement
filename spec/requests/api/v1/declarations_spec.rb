require "rails_helper"

RSpec.describe "Declaration endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Declarations::Query }
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_version) { :v1 }

  def create_resource(**attrs)
    if attrs[:user]
      attrs[:application] = create(:application, user: attrs[:user])
      attrs.delete(:user)
    end

    if attrs[:cohort] && !attrs[:course_cohort]
      attrs[:course_cohort] = create(:course_cohort, cohort: attrs[:cohort])
    end
    attrs.delete(:cohort)

    create(:declaration, **attrs)
  end

  RSpec.shared_examples "changing a declaration by another lead provider" do
    let(:application) { create(:application, lead_provider: current_lead_provider) }
    let(:resource) { create(:declaration, application:, lead_provider: create(:lead_provider)) }

    before do
      allow(Feature).to receive(:lp_transferred_declarations_visibility?).and_return(true)
      allow(service).to receive(:new).and_return(instance_double(service))
    end

    it "does not call the service" do
      expect(service).not_to receive(:new)
      api_put(path(resource_id))
    end

    it "returns 403 - forbidden" do
      api_put(path(resource_id))
      expect(response.status).to eq(403)
    end
  end

  describe "GET /api/v1/declarations" do
    let(:path) { api_v1_declarations_path }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by cohort"
  end

  describe "GET /api/v1/declarations/:ecf_id" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_declaration_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v1/declarations/:ecf_id/void" do
    let(:expected_data_id) { declaration.ecf_id }
    let(:params) { {} }
    let(:declaration) { nil }

    context "when declaration should be clawback" do
      let(:application) { create(:application, status: Application::STARTED, lead_provider: current_lead_provider) }
      let(:declaration) { create(:declaration, :submitted, application:, course_cohort: application.course_cohort, lead_provider: current_lead_provider) }

      before do
        api_put(void_api_v1_declaration_path(ecf_id: declaration.ecf_id), params:)
      end

      it_behaves_like "a successful api call"
    end

    context "when declaration should be voided" do
      let(:statement) { create(:statement, :next_output_fee, lead_provider: current_lead_provider) }
      let(:course_cohort) { create(:course_cohort, cohort: statement.cohort) }
      let(:application) { create(:application, status: Application::STARTED, course_cohort:, lead_provider: current_lead_provider) }
      let(:declaration) { create(:declaration, :paid, application:, course_cohort:, lead_provider: current_lead_provider) }

      before do
        api_put(void_api_v1_declaration_path(ecf_id: declaration.ecf_id), params:)
      end

      it_behaves_like "a successful api call"
    end
  end

  describe "PUT /api/v1/declarations/:ecf_id/change-delivery-partner" do
    let(:cohort) { create(:cohort, :current) }

    let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:new_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:new_secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:delivery_partner_id) { new_delivery_partner.ecf_id }
    let(:secondary_delivery_partner_id) { new_secondary_delivery_partner.ecf_id }

    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::ChangeDeliveryPartner }
    let(:action) { :change_delivery_partner }

    let(:service_args) { { declaration: resource, delivery_partner_id:, secondary_delivery_partner_id: } }

    let(:attributes) do
      {
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end

    def path(id = nil)
      change_delivery_partner_api_v1_declaration_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
    it_behaves_like "changing a declaration by another lead provider"

    context "when a parameter is missing" do
      let(:attributes) do
        {
          secondary_delivery_partner_id:,
        }
      end

      let(:params) { { data: {} } }

      before do
        api_put(path(resource_id), params:)
      end

      it "has proper response status" do
        expect(response.status).to eq(400)
      end
    end
  end
end
