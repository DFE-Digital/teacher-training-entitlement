require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /registrations/:journey_slug/:step_slug" do
    it "does not pre-select radio buttons when configured answers have no explicit values" do
      journey = RegistrationJourney.create!(name: "Food journey", slug: "food-journey")
      step = journey.registration_steps.create!(
        name: "What kind of meal are you planning?",
        slug: "meal-kind",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "Breakfast" },
              { "name" => "Lunch" },
              { "name" => "Dinner" },
            ],
          },
        },
      )

      get registration_path(journey.slug, step.slug)

      document = Nokogiri::HTML(response.body)
      radio_buttons = document.css("input[type='radio'][name='meal-kind[step_answer]']")

      expect(radio_buttons.map { |radio_button| radio_button["value"] }).to eq(%w[breakfast lunch dinner])
      expect(radio_buttons.css("[checked]")).to be_empty
    end
  end

  describe "PATCH /registrations/:journey_slug/:step_slug" do
    it "shows an error when a radio button step is submitted without an answer" do
      journey = RegistrationJourney.create!(name: "Simple journey", slug: "simple-journey")
      step = journey.registration_steps.create!(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
        config: {
          "radio_buttons" => {
            "answers" => [{ "name" => "Coffee", "value" => "coffee" }],
          },
        },
      )

      patch registration_path(journey.slug, step.slug), params: { step.slug => {} }

      expect(response.body).to include("Select an answer")
    end
  end
end
