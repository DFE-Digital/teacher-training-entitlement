require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }
  let(:session_data) { { user_id: user.id } }

  def stub_journey_wizard(journey)
    allow(Registrations::JourneyWizardFactory).to receive(:wizard) do |slug, **options|
      raise ActiveRecord::RecordNotFound unless slug == journey.slug

      Registrations::BaseJourneyWizard.new(journey_definition: journey, **options)
    end
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session_data)
    allow(Registrations::JourneyWizardFactory).to receive(:wizard).and_call_original
  end

  describe "GET /registrations/:journey_slug" do
    let(:journey) { create(:journey_definition, name: "SEND journey", slug: "send-journey") }
    let(:check_course) do
      create(:step_definition,
             journey_definition: journey,
             name: "Check course",
             slug: "check-course",
             type: "Registrations::StepDefinitions::Plain",
             config: {})
    end
    let(:teacher_catchment) do
      create(:step_definition,
             journey_definition: journey,
             name: "Do you work in England?",
             slug: "teacher-catchment",
             previous_step_slug: check_course.slug,
             type: "Registrations::StepDefinitions::RadioButtons",
             config: {})
    end
    let(:check_answers) do
      create(:step_definition,
             journey_definition: journey,
             name: "Check answers",
             slug: "check-answers",
             previous_step_slug: teacher_catchment.slug,
             type: "Registrations::StepDefinitions::CheckAnswers",
             config: {})
    end

    before do
      stub_journey_wizard(journey)
      check_answers
      check_course.set_answer_options!(answers: [
        {
          name: "Self-funded",
          value: "true",
          state_store_key: "self_funded",
          next_step_slug: check_answers.slug,
        },
      ])
    end

    context "when self-funded is true" do
      let(:session_data) { super().merge(registrations: { self_funded: "true" }) }

      it "redirects to check answers, skipping the check-course step" do
        get "/registrations/#{journey.slug}"

        expect(response).to redirect_to(step_registration_path(journey.slug, check_answers.slug))
      end
    end

    context "when self-funded is false" do
      let(:session_data) { super().merge(registrations: { self_funded: "false" }) }

      it "shows the check-course step" do
        get "/registrations/#{journey.slug}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check course")
      end
    end

    context "when self-funded is missing" do
      it "shows the check-course step" do
        get "/registrations/#{journey.slug}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check course")
      end
    end

    context "when the root step is requested explicitly" do
      let(:session_data) { super().merge(registrations: { self_funded: "true" }) }

      it "shows the check-course step rather than applying entry routing" do
        get step_registration_path(journey.slug, check_course.slug)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check course")
      end
    end
  end

  describe "GET /registrations/:journey_slug/:step_slug" do
    let(:journey) { create(:journey_definition, name: "Food journey", slug: "food-journey") }
    let(:step) do
      create(:step_definition,
             journey_definition: journey,
             name: "What kind of meal are you planning?",
             slug: "meal-kind",
             type: "Registrations::StepDefinitions::RadioButtons",
             config: {}).tap do |step_definition|
        step_definition.set_answer_options!(answers: [
          { "name" => "Breakfast", "value" => "breakfast" },
          { "name" => "Lunch", "value" => "lunch" },
          { "name" => "Dinner", "value" => "dinner" },
        ])
      end
    end

    before do
      stub_journey_wizard(journey)
    end

    it "does not pre-select radio buttons with explicitly configured values" do
      get step_registration_path(journey.slug, step.slug)

      document = Nokogiri::HTML(response.body)
      radio_buttons = document.css("input[type='radio'][name='meal-kind[what_kind_of_meal_are_you_planning]']")

      expect(radio_buttons.map { |radio_button| radio_button["value"] }).to eq(%w[breakfast lunch dinner])
      expect(radio_buttons.css("[checked]")).to be_empty
    end
  end

  describe "PATCH /registrations/:journey_slug/:step_slug" do
    let(:journey) { create(:journey_definition, name: "Simple journey", slug: "simple-journey") }
    let(:step) do
      create(:step_definition,
             journey_definition: journey,
             name: "Choose a drink",
             slug: "choose-a-drink",
             type: "Registrations::StepDefinitions::RadioButtons",
             config: {}).tap do |step_definition|
        step_definition.set_answer_options!(answers: [{ "name" => "Coffee", "value" => "coffee" }])
      end
    end

    before do
      stub_journey_wizard(journey)
    end

    it "shows an error when a radio button step is submitted without an answer" do
      patch step_registration_path(journey.slug, step.slug), params: { step.slug => {} }

      expect(response.body).to include("Select an answer")
    end
  end
end
