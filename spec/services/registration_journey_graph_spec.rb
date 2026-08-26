require "rails_helper"

RSpec.describe RegistrationJourneyGraph do
  describe "#to_mermaid" do
    it "escapes backslashes and quotes in labels" do
      journey = RegistrationJourney.create!(name: "Escaping journey", slug: "escaping-journey")
      step = journey.registration_steps.create!(
        name: "Path \\ \"quoted\"",
        slug: "path-quoted",
        type: "Radio buttons",
        order: 1,
        config: {},
      )

      mermaid = described_class.new(journey).to_mermaid

      expect(mermaid).to include("step_#{step.id}[\"Path \\\\ \\\"quoted\\\"\"]")
    end

    it "shows labelled edges for explicit and default answer paths" do
      journey = RegistrationJourney.create!(name: "Funding journey", slug: "funding-journey")
      teacher_catchment = journey.registration_steps.create!(
        name: "Teacher Catchment",
        slug: "teacher-catchment",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      work_setting = journey.registration_steps.create!(
        name: "Tell us where you work",
        slug: "work-setting",
        type: "Radio buttons",
        order: 2,
        config: {},
      )
      funding_eligibility = journey.registration_steps.create!(
        name: "Funding eligibility results",
        slug: "funding-eligibility-results",
        type: "Custom view",
        order: 3,
        config: {},
      )

      teacher_catchment.set_answers!(
        answers: [
          { "name" => "England" },
          { "name" => "Not England", "next_step_id" => funding_eligibility.id },
        ],
      )

      mermaid = described_class.new(journey).to_mermaid

      expect(mermaid).to include(
        "step_#{teacher_catchment.id} -->|\"England\"| step_#{work_setting.id}",
      )
      expect(mermaid).to include(
        "step_#{teacher_catchment.id} -->|\"Not England\"| step_#{funding_eligibility.id}",
      )
    end
  end

  describe "#configuration_rows" do
    it "presents configured step references as names" do
      journey = RegistrationJourney.create!(name: "Nested journey", slug: "nested-journey")
      start_step = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      coffee_step = journey.registration_steps.create!(
        name: "Choose your coffee",
        slug: "choose-your-coffee",
        type: "Radio buttons",
        order: 2,
        config: { "previous_step_id" => start_step.id },
      )
      check_answers_step = journey.registration_steps.create!(
        name: "Check your answers",
        slug: "check-answers",
        type: "Check answers",
        order: 3,
        config: {},
      )

      start_step.set_answers!(
        answers: [
          { "name" => "Coffee", "next_step_id" => coffee_step.id },
          { "name" => "Skip", "next_step_id" => check_answers_step.id },
        ],
      )
      start_step.update!(branch_join_step_id: check_answers_step.id)

      expect(described_class.new(journey).configuration_rows.first).to eq(
        id: start_step.id,
        name: "Choose a drink",
        answer_names: %w[Coffee Skip],
        previous_step_name: nil,
        answer_next_steps: [
          { answer_name: "Coffee", step_name: "Choose your coffee" },
          { answer_name: "Skip", step_name: "Check your answers" },
        ],
        branch_join_step_name: "Check your answers",
      )

      expect(described_class.new(journey).configuration_rows.second[:previous_step_name])
        .to eq("Choose a drink")
    end

    it "identifies a configured step that no longer exists" do
      journey = RegistrationJourney.create!(name: "Broken journey", slug: "broken-journey")
      journey.registration_steps.create!(
        name: "Choose an option",
        slug: "choose-an-option",
        type: "Radio buttons",
        order: 1,
        config: { "branch_join_step_id" => 999_999 },
      )

      row = described_class.new(journey).configuration_rows.first

      expect(row[:branch_join_step_name]).to eq("Unknown step (999999)")
    end

    it "includes steps without answer data" do
      journey = RegistrationJourney.create!(name: "Simple food", slug: "simple-food")
      food_mood = journey.registration_steps.create!(
        name: "Which food mood are you in?",
        slug: "food-mood",
        type: "Radio buttons",
        order: 1,
        config: {},
      )
      funding_results = journey.registration_steps.create!(
        name: "Funding eligibility results",
        slug: "funding-eligibility-results",
        type: "Custom view",
        order: 2,
        config: { "previous_step_id" => food_mood.id },
      )
      check_answers = journey.registration_steps.create!(
        name: "Check answers",
        slug: "check-answers",
        type: "Check answers",
        order: 3,
        config: { "previous_step_id" => funding_results.id },
      )

      rows = described_class.new(journey).configuration_rows

      expect(rows.pluck(:id)).to eq([food_mood.id, funding_results.id, check_answers.id])
      expect(rows.second).to include(
        answer_names: [],
        previous_step_name: "Which food mood are you in?",
        answer_next_steps: [],
      )
    end
  end
end
