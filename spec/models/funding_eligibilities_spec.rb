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
end
