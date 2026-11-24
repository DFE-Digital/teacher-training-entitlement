require "rails_helper"

RSpec.describe Registrations::StepDefinitions::HtmlPartial do
  describe "#set_html_partial!" do
    let(:step) do
      create(:step_definition, type: described_class.name, config: {})
    end
    let(:partial_name) { "registrations/excellence_in_reception/npd_start" }

    it "stores the partial name on the HtmlPartial definition" do
      step.set_html_partial!(partial_name:)

      expect(step.step_class).to eq(described_class)
      expect(step.partial_name).to eq(partial_name)
    end

    context "when the partial name is blank" do
      let(:partial_name) { "" }

      it "does not set a partial" do
        step.set_html_partial!(partial_name:)

        expect(step.partial_name).to be_nil
      end
    end
  end
end
