require "rails_helper"

RSpec.describe Admin::Finance::StatementsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { statements.first }

  let!(:statements) do
    [
      create(:statement, lead_provider:, start_date: Date.new(2024, 10, 1)),
      create(:statement, lead_provider:, start_date: Date.new(2024, 11, 1)),
      create(:statement, lead_provider:, start_date: Date.new(2024, 12, 1), output_fee: false),
    ]
  end

  before { sign_in_as_admin }

  describe "/admin/statements" do
    subject do
      get(admin_finance_statements_path, params:)
      response
    end

    context "with no params" do
      let(:params) { nil }

      it { is_expected.to have_http_status(:ok) }

      it "defaults to showing only statements with output_fee true" do
        subject
        expect(response.body).to match(/October 2024<\/td>/)
        expect(response.body).to match(/November 2024<\/td>/)
        expect(response.body).not_to match(/December 2024<\/td>/)
      end
    end

    context "with params matching multiple statements" do
      let(:params) do
        {
          lead_provider_id: statement.lead_provider_id,
        }
      end

      it { is_expected.to have_http_status(:ok) }
    end

    context "with params matching multiple statements using output fee" do
      let(:params) do
        {
          output_fee: "true",
        }
      end

      it { is_expected.to have_attributes body: %r{October 2024</td>} }
      it { is_expected.to have_attributes body: %r{November 2024</td>} }
      it { is_expected.not_to have_attributes body: %r{December 2024</td>} }
    end

    context "with output_fee set to false" do
      let(:params) do
        {
          output_fee: "false",
        }
      end

      it "shows only statements without output_fee" do
        subject
        expect(response.body).not_to match(/October 2024<\/td>/)
        expect(response.body).not_to match(/November 2024<\/td>/)
        expect(response.body).to match(/December 2024<\/td>/)
      end
    end

    context "with output_fee explicitly set to blank (user selected 'All')" do
      let(:params) do
        {
          output_fee: "",
        }
      end

      it "shows all statements regardless of output_fee" do
        subject
        expect(response.body).to match(/October 2024<\/td>/)
        expect(response.body).to match(/November 2024<\/td>/)
        expect(response.body).to match(/December 2024<\/td>/)
      end
    end

    context "with params matching no statement statement" do
      let(:params) do
        {
          lead_provider_id: statement.lead_provider_id,
          statement: "2000-01",
        }
      end

      it { is_expected.to have_http_status(:ok) }
    end
  end

  describe "/admin/statements/{id}" do
    subject do
      get admin_finance_statement_path(statement_id)
      response
    end

    context "when statement exists" do
      let(:statement_id) { statement.id }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when the statement cannot be found", :exceptions_app do
      let(:statement_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
