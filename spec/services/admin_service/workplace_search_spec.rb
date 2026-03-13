require "rails_helper"

RSpec.describe AdminService::WorkplaceSearch do
  let(:offset) { 0 }
  let(:limit) { 10 }

  subject { described_class.new(q:).limit(limit).offset(offset) }

  describe "searching" do
    context "when school matches the criteria" do
      let!(:school) { create(:school) }

      context "when partial name match" do
        let(:q) { school.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([school])
        end
      end

      context "when school#urn match" do
        let(:q) { school.urn }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([school])
        end
      end
    end

    context "when private childcare provider matches the criteria" do
      let!(:workplace) { create(:private_childcare_provider) }

      context "when partial name match" do
        let(:q) { workplace.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([workplace])
        end
      end

      context "when provider_urn match" do
        let(:q) { workplace.urn }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([workplace])
        end
      end
    end

    context "when local authority matches the criteria" do
      let!(:workplace) { create(:local_authority) }

      context "when partial name match" do
        let(:q) { workplace.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([workplace])
        end
      end
    end
  end

  describe "pagination" do
    let(:q) { nil }
    let!(:school1) { create(:school, name: "ASchool 1") }
    let!(:school2) { create(:school, name: "BSchool 2") }
    let!(:pcp1) { create(:private_childcare_provider, name: "CPCP 1") }
    let!(:pcp2) { create(:private_childcare_provider, name: "DPCP 2") }
    let!(:la1) { create(:local_authority, name: "EBarnet") }
    let!(:la2) { create(:local_authority, name: "FEaling") }

    context "when limit is higher than all records counts" do
      # Results are sorted by name alphabetically across all institution types
      let(:result) { [school1, school2, pcp1, pcp2, la1, la2] }

      it "displays all records" do
        expect(subject.each.to_a).to eq(result)
      end
    end

    context "when limit is set to 2" do
      let(:limit) { 2 }

      context "when viewing first page" do
        let(:offset) { 0 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([school1, school2])
        end
      end

      context "when viewing second page" do
        let(:offset) { 2 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([pcp1, pcp2])
        end
      end

      context "when viewing third page" do
        let(:offset) { 4 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([la1, la2])
        end
      end
    end

    context "when limit is set to 5" do
      let(:limit) { 5 }

      context "when viewing first page" do
        let(:offset) { 0 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([school1, school2, pcp1, pcp2, la1])
        end
      end

      context "when viewing second page" do
        let(:offset) { 5 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([la2])
        end
      end
    end
  end
end
