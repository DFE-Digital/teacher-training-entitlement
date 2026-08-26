require "rails_helper"

RSpec.describe Forms::RadioButtonsStepForm do
  subject(:form) { described_class.new(step_answer:) }

  let(:step_answer) { "Yes" }

  it { is_expected.to be_valid }

  context "when no answer has been selected" do
    let(:step_answer) { nil }

    it "is invalid" do
      expect(form).not_to be_valid
      expect(form.errors[:step_answer]).to include("Select an answer")
    end
  end
end
