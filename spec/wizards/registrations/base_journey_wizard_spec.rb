require "rails_helper"

RSpec.describe Registrations::BaseJourneyWizard do
  let(:journey_definition) { build(:journey_definition, name: "Demo journey", slug: "demo") }
  let(:config) do
    {
      "services" => [
        { "class_name" => "Registrations::BeforeShowService", "execute_point" => "before_show" },
        { class_name: "Registrations::AfterUpdateService", execute_point: :after_update },
      ],
    }
  end
  let(:step_definition) do
    build(
      :step_definition,
      journey_definition:,
      name: "Start",
      slug: "start",
      type: "Registrations::StepDefinitions::Plain",
      config:,
    )
  end
  let(:wizard) do
    step_definition
    described_class.new(journey_definition:, session: {}, current_step: :start)
  end
  let(:wizard_step) { wizard.current_step }

  describe "#execute_services" do
    it "runs the services configured for the requested execute point" do
      before_show_service_class = Class.new do
        def initialize(wizard_step:); end
        def call; end
      end
      after_update_service_class = Class.new do
        def initialize(wizard_step:); end
        def call; end
      end
      stub_const("Registrations::BeforeShowService", before_show_service_class)
      stub_const("Registrations::AfterUpdateService", after_update_service_class)

      before_show_service = instance_double(before_show_service_class)
      allow(before_show_service_class).to receive(:new).with(wizard_step:).and_return(before_show_service)
      expect(before_show_service_class).to receive(:new).with(wizard_step:)
      expect(before_show_service).to receive(:call)
      expect(after_update_service_class).not_to receive(:new)

      wizard.execute_services(execute_point: :before_show)
    end

    it "supports symbol-keyed configuration and symbol execute points" do
      after_update_service_class = Class.new do
        def initialize(wizard_step:); end
        def call; end
      end
      stub_const("Registrations::AfterUpdateService", after_update_service_class)
      after_update_service = instance_double(after_update_service_class)
      allow(after_update_service_class).to receive(:new).with(wizard_step:).and_return(after_update_service)
      expect(after_update_service_class).to receive(:new).with(wizard_step:)
      expect(after_update_service).to receive(:call)

      wizard.execute_services(execute_point: "after_update")
    end

    context "when no services are configured" do
      let(:config) { {} }

      it "does nothing" do
        expect { wizard.execute_services(execute_point: :before_show) }.not_to raise_error
      end
    end
  end
end
