require "rails_helper"

RSpec.describe RegistrationJourney do
  describe "#set_slug callback" do
    it "creates a slug from the name and preserves an existing slug" do
      registration_journey = build(:registration_journey, name: "A Journey Name", slug: nil)
      registration_journey.save!

      expect(registration_journey.slug).to eq("a-journey-name")

      registration_journey.update!(name: "A Different Name")

      expect(registration_journey.slug).to eq("a-journey-name")
    end
  end
end
