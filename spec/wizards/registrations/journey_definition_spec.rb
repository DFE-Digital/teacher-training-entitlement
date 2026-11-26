require "rails_helper"

RSpec.describe Registrations::JourneyDefinition do
  describe "#initialize" do
    it "derives a slug from the name when one is not supplied" do
      journey = described_class.new(name: "A Journey Name")

      expect(journey.slug).to eq("a-journey-name")
    end
  end

  describe "#add_step" do
    it "adds the step and assigns its journey" do
      journey = described_class.new(name: "Demo")
      step = Registrations::StepDefinition.new(name: "Start")

      expect(journey.add_step(step)).to eq(step)
      expect(journey.step_definitions).to contain_exactly(step)
      expect(step.journey_definition).to eq(journey)
    end
  end
end
