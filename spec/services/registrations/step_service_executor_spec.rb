require "rails_helper"

RSpec.describe Registrations::StepServiceExecutor do
  let(:config) do
    {
      "services" => [
        { "class_name" => "Registrations::BeforeShowService", "execute_point" => "before_show" },
        { class_name: "Registrations::AfterUpdateService", execute_point: :after_update },
      ],
    }
  end
  let(:registration_step) { instance_double(RegistrationStep, config:) }
  let(:router_step) { instance_double(Registrations::RouterStep, registration_step:) }

  describe "#call" do
    it "runs the services configured for the requested execute point" do
      before_show_service_class = Class.new do
        def initialize(router_step:); end
        def call; end
      end
      after_update_service_class = Class.new do
        def initialize(router_step:); end
        def call; end
      end
      stub_const("Registrations::BeforeShowService", before_show_service_class)
      stub_const("Registrations::AfterUpdateService", after_update_service_class)

      before_show_service = instance_double(before_show_service_class)
      allow(before_show_service_class).to receive(:new).with(router_step:).and_return(before_show_service)
      expect(before_show_service_class).to receive(:new).with(router_step:)
      expect(before_show_service).to receive(:call)
      expect(after_update_service_class).not_to receive(:new)

      described_class.new(router_step:, execute_point: :before_show).call
    end

    it "supports symbol-keyed configuration and symbol execute points" do
      after_update_service_class = Class.new do
        def initialize(router_step:); end
        def call; end
      end
      stub_const("Registrations::AfterUpdateService", after_update_service_class)
      after_update_service = instance_double(after_update_service_class)
      allow(after_update_service_class).to receive(:new).with(router_step:).and_return(after_update_service)
      expect(after_update_service_class).to receive(:new).with(router_step:)
      expect(after_update_service).to receive(:call)

      described_class.new(router_step:, execute_point: "after_update").call
    end

    context "when no services are configured" do
      let(:config) { {} }

      it "does nothing" do
        expect { described_class.new(router_step:, execute_point: :before_show).call }.not_to raise_error
      end
    end
  end
end
