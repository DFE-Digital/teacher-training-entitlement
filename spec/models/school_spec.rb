require "rails_helper"

RSpec.describe School do
  describe ".primary_education_phase?" do
    let(:school) do
      build(:school,
            phase_name: phase)
    end
    let(:primary_phases) do
      [described_class::PRIMARY_PHASE,
       described_class::MIDDLE_DEEMED_PRIMARY_PHASE]
    end
    let(:non_primary_phase) { "Secondary" }

    context "when school phase_name is primary" do
      [described_class::PRIMARY_PHASE,
       described_class::MIDDLE_DEEMED_PRIMARY_PHASE].each do |phase|
        let(:phase) { phase }
        it "returns true" do
          expect(school).to be_primary_education_phase
        end
      end
    end

    context "when school phase_name is not primary" do
      let(:phase) { non_primary_phase }

      it "returns false" do
        expect(school).not_to be_primary_education_phase
      end
    end
  end

  describe "#eligible_establishment?" do
    subject { school.eligible_establishment? }

    let(:school) { build(:school, establishment_type_code: code) }

    context "when establishment_type_code is in the list" do
      let(:code) { School::ELIGIBLE_ESTABLISHMENT_TYPE_CODES.keys.first }

      it { is_expected.to be true }
    end

    context "when establishment_type_code is not in the list" do
      let(:code) { "-1" }

      it { is_expected.to be false }
    end
  end
end
