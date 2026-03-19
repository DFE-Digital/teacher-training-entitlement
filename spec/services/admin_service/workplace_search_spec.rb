require "rails_helper"

RSpec.describe AdminService::WorkplaceSearch do
  let(:offset) { 0 }
  let(:limit) { 10 }

  subject { described_class.new(q:).limit(limit).offset(offset) }

  describe "searching" do
    context "when school institution matches the criteria" do
      let!(:institution) { create(:institution, :for_school) }

      context "when partial name match" do
        let(:q) { institution.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([institution])
        end
      end

      context "when URN match" do
        let(:q) { institution.urn }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([institution])
        end
      end
    end

    context "when private childcare provider institution matches the criteria" do
      let!(:institution) { create(:institution, :for_private_childcare_provider) }

      context "when partial name match" do
        let(:q) { institution.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([institution])
        end
      end

      context "when URN match" do
        let(:q) { institution.urn }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([institution])
        end
      end
    end

    context "when local authority institution matches the criteria" do
      let!(:institution) { create(:institution, :for_local_authority) }

      context "when partial name match" do
        let(:q) { institution.name.split(" ").first }

        it "returns the hit" do
          expect(subject.each.to_a).to eq([institution])
        end
      end
    end
  end

  describe "pagination" do
    let(:q) { nil }
    let!(:institution1) { create(:institution, :for_school, name: "ASchool 1") }
    let!(:institution2) { create(:institution, :for_school, name: "BSchool 2") }
    let!(:institution3) { create(:institution, :for_private_childcare_provider, name: "CPCP 1") }
    let!(:institution4) { create(:institution, :for_private_childcare_provider, name: "DPCP 2") }
    let!(:institution5) { create(:institution, :for_local_authority, name: "EBarnet") }
    let!(:institution6) { create(:institution, :for_local_authority, name: "FEaling") }

    context "when limit is higher than all records counts" do
      # Results are sorted by name alphabetically across all institution types
      it "displays all records" do
        expect(subject.each.to_a).to eq([institution1, institution2, institution3, institution4, institution5, institution6])
      end
    end

    context "when limit is set to 2" do
      let(:limit) { 2 }

      context "when viewing first page" do
        let(:offset) { 0 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([institution1, institution2])
        end
      end

      context "when viewing second page" do
        let(:offset) { 2 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([institution3, institution4])
        end
      end

      context "when viewing third page" do
        let(:offset) { 4 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([institution5, institution6])
        end
      end
    end

    context "when limit is set to 5" do
      let(:limit) { 5 }

      context "when viewing first page" do
        let(:offset) { 0 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([institution1, institution2, institution3, institution4, institution5])
        end
      end

      context "when viewing second page" do
        let(:offset) { 5 }

        it "displays correct records" do
          expect(subject.each.to_a).to eq([institution6])
        end
      end
    end
  end
end
