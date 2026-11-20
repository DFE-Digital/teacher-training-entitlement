require "rails_helper"

RSpec.describe RegistrationSteps::ViewComponent do
  describe "#set_view_component!" do
    let(:step) do
      create(:registration_step, type: described_class.name, config: {})
    end
    let(:component_class_name) { "Registrations::CourseStartDateComponent" }

    it "stores the component class name and resolves the component class" do
      step.set_view_component!(component_class_name:)

      expect(step.reload).to be_a(described_class)
      expect(step.view_component_class_name).to eq(component_class_name)
      expect(step.view_component_class).to eq(Registrations::CourseStartDateComponent)
    end

    context "when the class is not a registration ViewComponent" do
      let(:component_class_name) { "String" }

      it "does not store it as the configured component" do
        step.set_view_component!(component_class_name:)

        expect(step.reload.view_component_class_name).to be_nil
      end
    end
  end
end
