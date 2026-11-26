require "rails_helper"

RSpec.describe Registrations::BaseJourneyWizard do
  describe "#execute_services" do
    let(:wizard) { described_class.allocate }
    let(:current_step) { double }

    before do
      allow(wizard).to receive(:current_step).and_return(current_step)
    end

    it "delegates the execution point to the current step" do
      expect(current_step).to receive(:after_update)

      wizard.execute_services(execute_point: :after_update)
    end

    it "does nothing when the current step does not implement the execution point" do
      expect { wizard.execute_services(execute_point: :before_show) }.not_to raise_error
    end
  end
end
