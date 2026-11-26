require "rails_helper"

RSpec.describe RegistrationJourney do
  describe "#initialize" do
    it "derives a slug from the name when one is not supplied" do
      journey = described_class.new(name: "A Journey Name")

      expect(journey.slug).to eq("a-journey-name")
    end
  end

  describe "#add_step" do
    it "adds the step and assigns its journey" do
      journey = described_class.new(name: "Demo")
      step = RegistrationStep.new(name: "Start")

      expect(journey.add_step(step)).to eq(step)
      expect(journey.registration_steps).to contain_exactly(step)
      expect(step.registration_journey).to eq(journey)
    end
  end

  describe "#start_step" do
    it "returns the only step without an incoming transition" do
      journey = described_class.new(name: "Demo")
      start = RegistrationStep.new(name: "Start")
      finish = RegistrationStep.new(name: "Finish", previous_step_id: start.id)
      journey.add_step(start)
      journey.add_step(finish)

      expect(journey.start_step).to eq(start)
    end

    it "raises when the journey has more than one root" do
      journey = described_class.new(name: "Demo")
      journey.add_step(RegistrationStep.new(name: "First"))
      journey.add_step(RegistrationStep.new(name: "Second"))

      expect { journey.start_step }.to raise_error(ArgumentError, /exactly one start step/)
    end
  end
end
