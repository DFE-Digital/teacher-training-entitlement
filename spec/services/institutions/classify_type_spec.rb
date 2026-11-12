require "rails_helper"

RSpec.describe Institutions::ClassifyType do
  subject(:slug) { described_class.new(institutionable:, name:).call }

  let(:name) { "Some Place" }

  context "with a state funded school" do
    let(:institutionable) { build(:school, establishment_type_code: "1") }

    it { is_expected.to eq("state_funded") }
  end

  context "with a further education school (type 18)" do
    let(:institutionable) { build(:school, establishment_type_code: "18") }

    it { is_expected.to eq("further_education") }
  end

  context "with a state funded school whose name looks like a hospital" do
    let(:institutionable) { build(:school, establishment_type_code: "1") }
    let(:name) { "Royal Hospital School" }

    it "keeps state_funded because it is evaluated first" do
      expect(slug).to eq("state_funded")
    end
  end

  context "with a non eligible school whose name contains hospital" do
    let(:institutionable) { build(:school, establishment_type_code: "99") }
    let(:name) { "Great Ormond Street Hospital School" }

    it { is_expected.to eq("hospital") }
  end

  context "with a non eligible school matching no selector" do
    let(:institutionable) { build(:school, establishment_type_code: "99") }

    it { is_expected.to eq("state_funded") }
  end

  context "with a local authority" do
    let(:institutionable) { build(:local_authority) }

    it { is_expected.to eq("local_authority") }
  end

  context "with a private childcare provider" do
    let(:institutionable) { build(:private_childcare_provider) }

    it { is_expected.to eq("private_childcare_provider") }
  end
end
