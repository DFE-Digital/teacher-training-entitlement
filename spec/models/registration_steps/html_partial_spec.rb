require "rails_helper"

RSpec.describe RegistrationSteps::HtmlPartial do
  describe "#set_html_partial!" do
    let(:step) do
      create(:registration_step, type: described_class.name, config: {})
    end
    let(:partial_name) { "registrations/excellence_in_reception/npd_start" }

    it "stores the partial name on the HtmlPartial STI type" do
      step.set_html_partial!(partial_name:)

      expect(step.reload).to be_a(described_class)
      expect(step.partial_name).to eq(partial_name)
    end

    context "when the partial name is blank" do
      let(:partial_name) { "" }

      it "does not set a partial" do
        step.set_html_partial!(partial_name:)

        expect(step.reload.partial_name).to be_nil
      end
    end
  end
end
