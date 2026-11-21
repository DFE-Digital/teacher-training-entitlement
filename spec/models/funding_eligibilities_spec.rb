require "rails_helper"

RSpec.describe FundingEligibilities do
  describe ".available" do
    it "lists the state funded school rule set" do
      expect(described_class.available.map { [_1.key, _1.name] }).to eq([["state_funded_school", "State-funded school"]])
    end
  end

  describe ".keys" do
    it "returns the registry keys" do
      expect(described_class.keys).to eq(%w[state_funded_school])
    end
  end

  describe ".name_for" do
    it "returns the rule set name for a known key" do
      expect(described_class.name_for("state_funded_school")).to eq("State-funded school")
    end

    it "returns nil for an unknown key" do
      expect(described_class.name_for("unknown")).to be_nil
    end
  end
end
