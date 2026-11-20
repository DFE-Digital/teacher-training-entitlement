require "rails_helper"

RSpec.describe Registrations::RouterStep do
  describe "answer context" do
    let(:journey) { create(:registration_journey, name: "Simple journey", slug: "simple-journey") }
    let(:state_store_key) { nil }
    let(:step) do
      create(:registration_step,
             registration_journey: journey,
             name: "Choose a drink",
             state_store_key:,
             slug: "choose-a-drink",
             type: "RegistrationSteps::RadioButtons",
             config: {}).tap do |registration_step|
        registration_step.set_answers!(answers: [{ name: "Coffee", value: "coffee" }])
      end
    end
    let(:params) do
      ActionController::Parameters.new(
        "journey_slug" => journey.slug,
        "step_slug" => step.slug,
        "choose-a-drink" => { step_answer: "coffee" },
      )
    end
    let(:router_step) do
      described_class.new(params:, session: {})
    end

    it "exposes the request answer and step context" do
      expect(router_step.step_answer).to eq("coffee")
      expect(router_step.slug).to eq(:"choose-a-drink")
      expect(router_step.registration_journey_slug).to eq("simple-journey")
    end

    context "when the step params use the configured answer key" do
      let(:state_store_key) { "drink_choice" }
      let(:params) do
        ActionController::Parameters.new(
          "journey_slug" => journey.slug,
          "step_slug" => step.slug,
          "choose-a-drink" => { "drink_choice" => "dave" },
        )
      end

      it "reads the answer from that key" do
        expect(router_step.step_answer).to eq("dave")
      end
    end
  end

  describe "#valid?" do
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
    let(:params) do
      ActionController::Parameters.new(
        "journey_slug" => journey.slug,
        "step_slug" => step.slug,
        "choose-a-drink" => { step_answer: "coffee" },
      )
    end
    let(:router_step) do
      described_class.new(params:, session: {})
    end

    it "returns true when a radio button step has a selected answer" do
      expect(router_step.registration_step).to eq(step)
      expect(router_step.valid?).to be true
    end

    context "when no answer is selected" do
      let(:params) do
        ActionController::Parameters.new(
          "journey_slug" => journey.slug,
          "step_slug" => step.slug,
          "choose-a-drink" => {},
        )
      end

      it "returns false and adds a validation error" do
        expect(router_step.valid?).to be false
        expect(router_step.errors[:step_answer]).to include("Select an answer")
      end
    end
  end

  describe "#store_answer!" do
    context "with a simple step" do
      let(:journey) { create(:registration_journey, name: "Simple journey", slug: "simple-journey") }
      let(:step_name) { "Choose a drink" }
      let(:step_slug) { "choose-a-drink" }
      let(:state_store_key) { nil }
      let(:answer) { "Coffee" }
      let(:step) do
        create(:registration_step,
               registration_journey: journey,
               name: step_name,
               state_store_key:,
               slug: step_slug,
               type: "RegistrationSteps::RadioButtons",
               config: {}).tap do |registration_step|
          registration_step.set_answers!(answers: [{ "name" => answer }])
        end
      end
      let(:params) do
        ActionController::Parameters.new(
          "journey_slug" => journey.slug,
          "step_slug" => step.slug,
          step_slug => { step_answer: answer },
        )
      end
      let(:router_step) do
        described_class.new(params:, session: {})
      end

      it "stores the answer under the parameterized step name" do
        router_step.store_answer!

        expect(router_step.state_store.read.to_h.symbolize_keys).to eq(choose_a_drink: "Coffee")
      end

      context "with a custom answer key" do
        let(:step_name) { "Choose your provider" }
        let(:step_slug) { "choose-your-provider" }
        let(:state_store_key) { "lead_provider_id" }
        let(:answer) { "Provider One" }

        it "stores the answer under that key" do
          router_step.store_answer!

          expect(router_step.state_store.read.to_h.symbolize_keys).to eq(lead_provider_id: "Provider One")
        end
      end
    end

    context "with a branching step" do
      let(:journey) { create(:registration_journey, name: "Branch journey", slug: "branch-journey") }
      let(:state_store_key) { nil }
      let(:coffee_answer_key) { nil }
      let(:step_name) { "Choose a drink" }
      let(:step_slug) { "choose-a-drink" }
      let(:state_before_change) { { choose_a_drink: "coffee", choose_your_coffee: "Black" } }
      let(:params) do
        ActionController::Parameters.new(
          "journey_slug" => journey.slug,
          "step_slug" => step_slug,
          step_slug => { step_answer: "tea" },
        )
      end
      let!(:choice) do
        create(:registration_step,
               registration_journey: journey,
               name: step_name,
               state_store_key:,
               slug: step_slug,
               type: "RegistrationSteps::RadioButtons",
               config: {})
      end
      let!(:coffee_detail) do
        create(:registration_step,
               registration_journey: journey,
               name: "Choose your coffee",
               state_store_key: coffee_answer_key,
               slug: "choose-your-coffee",
               type: "RegistrationSteps::RadioButtons",
               previous_step_id: choice.id,
               config: {})
      end
      let!(:tea_detail) do
        create(:registration_step,
               registration_journey: journey,
               name: "Choose your tea",
               state_store_key: "tea_detail",
               slug: "choose-your-tea",
               type: "RegistrationSteps::RadioButtons",
               previous_step_id: choice.id,
               config: {})
      end
      let(:router) do
        Registrations::Router.new(params:, session: {})
      end

      before do
        choice.set_answers!(
          answers: [
            { "name" => "Coffee", "value" => "coffee", "next_step_id" => coffee_detail.id },
            { "name" => "Tea", "value" => "tea", "next_step_id" => tea_detail.id },
          ],
        )
        router.router_step.state_store.write(state_before_change)
      end

      it "clears answers from the previously selected branch" do
        expect(router.next_step_slug).to eq(:"choose-your-coffee")

        router.router_step.store_answer!

        expect(router.router_step.state_store.read.to_h.symbolize_keys).to eq(choose_a_drink: "tea")
        expect(router.next_step_slug).to eq(:"choose-your-tea")
      end

      context "when the step uses a custom answer key" do
        let(:state_store_key) { "drink_choice" }
        let(:coffee_answer_key) { "coffee_detail" }
        let(:state_before_change) { { drink_choice: "coffee", coffee_detail: "Black" } }

        it "clears answers from the previously selected branch" do
          router.router_step.store_answer!

          expect(router.router_step.state_store.read.to_h.symbolize_keys).to eq(drink_choice: "tea")
        end
      end
    end

    context "with a custom step" do
      let(:journey) { create(:registration_journey, name: "Custom journey", slug: "custom-journey") }
      let(:step) do
        create(:registration_step,
               registration_journey: journey,
               name: "Course start",
               slug: "course-start-date",
               state_store_key: "course_cohort_ecf_id",
               type: "RegistrationSteps::ViewComponent",
               config: {})
      end
      let(:params) do
        ActionController::Parameters.new(
          "journey_slug" => journey.slug,
          "step_slug" => step.slug,
          "course-start-date" => { step_answer: "cohort-ecf-id" },
        )
      end
      let(:router_step) do
        described_class.new(params:, session: {})
      end

      it "stores the answer like other registration steps" do
        router_step.store_answer!

        expect(router_step.state_store.read.to_h.symbolize_keys).to eq(course_cohort_ecf_id: "cohort-ecf-id")
      end
    end
  end
end
