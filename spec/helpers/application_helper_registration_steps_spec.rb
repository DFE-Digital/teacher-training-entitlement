require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#registration_step_display_value" do
    it "returns the configured answer name for a stored answer value" do
      journey = RegistrationJourney.create!(name: "Demo journey", slug: "demo-journey")
      step = journey.registration_steps.create!(
        name: "Work setting",
        answer_key: "work_setting",
        type: "Radio buttons",
        config: {},
      )
      step.set_answers!(
        answers: [
          {
            "name" => "State-funded nursery, pre-school, school or academy trust",
            "value" => Institution::STATE_FUNDED_INSTITUTION,
          },
        ],
      )

      expect(helper.registration_step_display_value(journey, :work_setting, Institution::STATE_FUNDED_INSTITUTION))
        .to eq("State-funded nursery, pre-school, school or academy trust")
    end

    it "returns the configured answer name for a derived stored answer value" do
      journey = RegistrationJourney.create!(name: "Demo journey", slug: "demo-journey")
      journey.registration_steps.create!(
        name: "Choose your extras",
        answer_key: "extras",
        type: "Checkboxes",
        config: {
          "checkboxes" => {
            "answers" => [
              { "name" => "Toasted seeds" },
            ],
          },
        },
      )

      expect(helper.registration_step_display_value(journey, :extras, "toasted_seeds"))
        .to eq("Toasted seeds")
    end

    it "returns the raw value when no configured answer matches" do
      journey = RegistrationJourney.create!(name: "Demo journey", slug: "demo-journey")

      expect(helper.registration_step_display_value(journey, :unknown, "raw-value"))
        .to eq("raw-value")
    end
  end
end
