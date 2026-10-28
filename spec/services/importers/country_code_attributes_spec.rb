require "rails_helper"

RSpec.describe Importers::CountryCodeAttributes do
  describe ".country_code_attributes_for" do
    subject(:attributes) { described_class.country_code_attributes_for(institutionable) }

    context "with a school" do
      let(:institutionable) { build(:school) }

      it { is_expected.to eq(alpha3_country_code: "GBR", subdivision_code: "ENG") }

      context "when the school is in Wales" do
        let(:institutionable) { build(:school, establishment_type_code: "30") }

        it { is_expected.to eq(alpha3_country_code: "GBR", subdivision_code: "WLS") }
      end

      context "when the school is overseas" do
        let(:institutionable) { build(:school, la_code: "704") }

        it { is_expected.to eq(alpha3_country_code: nil, subdivision_code: nil) }
      end
    end

    context "with a private childcare provider" do
      let(:institutionable) { build(:private_childcare_provider) }

      it { is_expected.to eq(alpha3_country_code: "GBR", subdivision_code: "ENG") }
    end

    context "with a local authority" do
      let(:institutionable) { build(:local_authority) }

      it { is_expected.to eq(alpha3_country_code: "GBR", subdivision_code: "ENG") }
    end
  end
end
