require "rails_helper"

RSpec.describe Registrations::FundingEligibility::FoodFundingEligibilityService do
  describe "#call" do
    it "marks Fresh and light choices as eligible for funding" do
      state_store = instance_double(DefaultStore)
      wizard = instance_double(FormWizard, state_store:)

      allow(state_store).to receive(:[]).with(:which_food_mood_are_you_in).and_return("Fresh and light")
      allow(state_store).to receive(:write)

      described_class.new(wizard:).call

      expect(state_store).to have_received(:write).with(
        complicated_food_funding_eligible: true,
        complicated_food_funding_eligibility_result: "You're eligible for funding, yay!",
      )
    end

    it "marks other choices as not eligible for funding" do
      state_store = instance_double(DefaultStore)
      wizard = instance_double(FormWizard, state_store:)

      allow(state_store).to receive(:[]).with(:which_food_mood_are_you_in).and_return("Comfort food")
      allow(state_store).to receive(:write)

      described_class.new(wizard:).call

      expect(state_store).to have_received(:write).with(
        complicated_food_funding_eligible: false,
        complicated_food_funding_eligibility_result: "Sorry, but funding is only available for people that like 'Fresh and light' !",
      )
    end
  end
end
