require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
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
