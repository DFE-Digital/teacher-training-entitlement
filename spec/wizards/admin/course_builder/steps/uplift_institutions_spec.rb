require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::UpliftInstitutions do
  subject(:step) { described_class.new(uplift_institution_ids:, uplift_institution_search:) }

  let(:uplift_institution_ids) { [] }
  let(:uplift_institution_search) { nil }
  let!(:sunny_school) { create(:institution, name: "Sunny Hill School") }
  let!(:sunny_nursery) { create(:institution, name: "Sunny Days Nursery") }
  let!(:rainy_school) { create(:institution, name: "Rainy Vale School") }

  describe "validations" do
    context "when no institution is selected" do
      it "is not valid" do
        expect(step).not_to be_valid
        expect(step.errors[:uplift_institution_ids]).to contain_exactly("Select at least one institution")
      end
    end

    context "when only unknown institutions are selected" do
      let(:uplift_institution_ids) { %w[0] }

      it { is_expected.not_to be_valid }
    end

    context "when an institution is selected" do
      let(:uplift_institution_ids) { [sunny_school.id.to_s] }

      it { is_expected.to be_valid }
    end
  end

  describe "#uplift_institution_ids" do
    let(:uplift_institution_ids) { ["", sunny_school.id.to_s, sunny_school.id.to_s, "abc"] }

    it "keeps unique integer ids only" do
      expect(step.uplift_institution_ids).to eq([sunny_school.id])
    end
  end

  describe "#search_results" do
    context "when there is no search term" do
      it { expect(step.search_results).to be_empty }
    end

    context "when there is a search term" do
      let(:uplift_institution_search) { "Sunny" }

      it "returns the matching institutions" do
        expect(step.search_results).to contain_exactly(sunny_school, sunny_nursery)
      end

      context "when a matching institution is already selected" do
        let(:uplift_institution_ids) { [sunny_school.id.to_s] }

        it "leaves it out" do
          expect(step.search_results).to contain_exactly(sunny_nursery)
        end
      end
    end
  end

  describe "#institution_options" do
    let(:uplift_institution_ids) { [rainy_school.id.to_s] }
    let(:uplift_institution_search) { "Sunny" }

    it "lists the selected institutions first, then the search results" do
      expect(step.institution_options).to eq([rainy_school, sunny_nursery, sunny_school])
    end
  end
end
