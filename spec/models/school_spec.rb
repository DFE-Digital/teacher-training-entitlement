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

  describe "#in_england?" do
    it "returns true" do
      expect(subject).to be_in_england
    end

    context "when school establishment_type_code is 30 (Welsh establishment)" do
      before do
        subject.establishment_type_code = "30"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '673' (Vale of Glamorgan)" do
      before do
        subject.la_code = "673"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '702' (BFPO Overseas Establishments)" do
      before do
        subject.la_code = "702"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '000' (Does not apply)" do
      before do
        subject.la_code = "000"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '704' (Fieldwork Overseas Establishments)" do
      before do
        subject.la_code = "704"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
      end
    end

    context "when school la_code is '708' (Gibraltar Overseas Establishments)" do
      before do
        subject.la_code = "708"
      end

      it "returns false" do
        expect(subject).not_to be_in_england
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

  describe "check PP50 CSV files are valid" do
    let(:school) { create(:school, urn:) }

    context "Local Authority Disadvantaged Nurseries (LA_DISADVANTAGED_NURSERIES)" do
      subject { school.la_disadvantaged_nursery? }

      let(:urn) { "126565" } # URN taken from data file

      it { is_expected.to be true }
    end

    context "Early Years Schools (EY_OFSTED_URN_HASH)" do
      subject { school.eyl_disadvantaged? }

      let(:urn) { "150014" } # URN taken from data file

      it { is_expected.to be true }
    end
  end
end
