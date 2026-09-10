require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::ContractFinancials do
  subject(:step) { described_class.new(contract_financials:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:contract_financials) { {} }

  describe "#contract_financial_selected?" do
    it "defaults to selected" do
      expect(step.contract_financial_selected?("generic", lead_provider)).to be true
    end

    context "when the lead provider has been unselected" do
      let(:contract_financials) do
        {
          "generic" => {
            lead_provider.id.to_s => {
              "selected" => "0",
            },
          },
        }
      end

      it "returns false" do
        expect(step.contract_financial_selected?("generic", lead_provider)).to be false
      end
    end
  end

  describe "#academic_year_keys" do
    subject(:step) do
      described_class.new(
        academic_years: %w[2028 2029],
        contract_financials: {
          "2027" => {
            lead_provider.id.to_s => {
              "selected" => "1",
            },
          },
        },
      )
    end

    it "returns generic, stored, submitted and default academic years" do
      expect(step.academic_year_keys).to eq(["generic", 2027, 2028, 2029])
    end
  end
end
