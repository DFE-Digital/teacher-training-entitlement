require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /registrations/:journey_slug/:step_slug" do
    let(:journey) { create(:registration_journey, name: "Food journey", slug: "food-journey") }
    let(:step) do
      create(:registration_step,
             registration_journey: journey,
             name: "What kind of meal are you planning?",
             slug: "meal-kind",
             type: "RegistrationSteps::RadioButtons",
             config: {}).tap do |registration_step|
        registration_step.set_answers!(answers: [
          { "name" => "Breakfast", "value" => "breakfast" },
          { "name" => "Lunch", "value" => "lunch" },
          { "name" => "Dinner", "value" => "dinner" },
        ])
      end
    end

    it "does not pre-select radio buttons with explicitly configured values" do
      get step_registration_path(journey.slug, step.slug)

      document = Nokogiri::HTML(response.body)
      radio_buttons = document.css("input[type='radio'][name='meal-kind[step_answer]']")

      expect(radio_buttons.map { |radio_button| radio_button["value"] }).to eq(%w[breakfast lunch dinner])
      expect(radio_buttons.css("[checked]")).to be_empty
    end
  end

  describe "PATCH /registrations/:journey_slug/:step_slug" do
    let(:journey) { create(:registration_journey, name: "Simple journey", slug: "simple-journey") }
    let(:step) do
      create(:registration_step,
             registration_journey: journey,
             name: "Choose a drink",
             slug: "choose-a-drink",
             type: "RegistrationSteps::RadioButtons",
             config: {}).tap do |registration_step|
        registration_step.set_answers!(answers: [{ "name" => "Coffee", "value" => "coffee" }])
      end
    end

    it "shows an error when a radio button step is submitted without an answer" do
      patch step_registration_path(journey.slug, step.slug), params: { step.slug => {} }

      expect(response.body).to include("Select an answer")
    end
  end
end
